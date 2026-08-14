# 010: ホスティング先（EC2 + Neon + Cloudflare Tunnel）

## 決定日

2026-08-14（issue #158 で記録。選定は tofu-dev0123/life#99 で実施）

## ステータス

決定済み

## 背景

バックエンドは Railway で運用しており **月 $20** かかっていた。Railway の料金体系は
Free($0 / $1 クレジット) / Hobby($5 / $5) / Pro($20 / $20) だが、
**Hobby では利用枠の上限に当たるため実質 Pro $20 が必要な状態だった。**
フロント（Next.js / Vercel）は $0 なので、コストはバックエンドに集中していた。

機能削減と [009: 認証方式](./009-authentication.md) の完了によって、選定の前提が変わった。

| 変化 | 効いたこと |
|---|---|
| アバターを削除し **S3 依存が消えた** | オブジェクトストレージが不要になった |
| テーブルが5つ消え、残り6テーブル | DB の要求容量が小さくなった |
| Clerk への外部依存が消えた | 認証 SaaS の課金要素が消えた |
| 想定トラフィックが確定した | **ユーザーは自分1人・閲覧者は数人** |

前提が変わったことで、$20 を払う構成が要件に対して過大になった。

---

## 決定内容

**EC2（東京・Graviton）にアプリを置き、DB は Neon、公開は Cloudflare Tunnel で行う。
インバウンドポートは1つも開けない。**

```
client → Cloudflare edge（TLS 終端・Universal SSL）
           └ Tunnel（outbound only）→ EC2 t4g.micro / ap-northeast-1
                                        ├ kamal-proxy（HTTP・TLS なし）
                                        └ Rails（Puma + Thruster）
DB   : Neon（外部・aws-ap-southeast-1）
シェル: SSM Session Manager（IAM 認証・鍵なし）
S3   : IAM インスタンスロール（アクセスキーを置かない）
インバウンド開放ポート: なし
```

| 項目 | 決定 |
|---|---|
| コンピュート | **EC2 `t4g.micro`（2vCPU / 1GB / arm64）・`ap-northeast-1`** |
| ストレージ | EBS gp3 20GB |
| DB | **Neon Free**（0.5GB / 5分でスケールゼロ） |
| 公開経路 | **Cloudflare Tunnel の public hostname** |
| TLS | **Cloudflare エッジで終端。オリジンに証明書を置かない** |
| デプロイ | **Kamal 2.11**（`ssl` 未指定＝HTTP-only + `forward_headers: true`） |
| シェル | SSM Session Manager |
| 購入方式 | **まずオンデマンド。1〜2ヶ月の稼働実績を見てから RI を購入する** |

---

## 前提となった実測

いずれもコードから確認した事実であり、推測ではない。

| 項目 | 実態 | 効いたこと |
|---|---|---|
| Redis | **不要** | `app/channels` が存在せず Gemfile にも redis が無い。`config/cable.yml` の production redis 設定は**死んだ設定** |
| バックグラウンドジョブ | **無し** | `ApplicationJob` のみ。ワーカー用の課金が不要 |
| オブジェクトストレージ | **不要** | アバター削除済み。`active_storage.service = :local` は未使用 |
| 永続ディスク | **不要** | アプリコンテナを使い捨てにできる |
| テーブル数 | 6 | |
| ドメイン制約 | **`COOKIE_DOMAIN` が親ドメイン共有前提** | API は `*.shelfie.jp` である必要がある |

ドメイン制約は [009: 認証方式](./009-authentication.md) の `SameSite=Lax` に由来する。
リフレッシュ Cookie がクロスサイトの `fetch` で送信されないため、
Next.js と Rails が同一の親ドメインに載ることが前提になっている。

---

## なぜ選定基準を組み替えたか

当初挙げていた5基準のうち **2つは候補を分けなかった**ため、選定から外した。

| 基準 | 採否 | 理由 |
|---|---|---|
| 月額 | 採用 | レンジが ¥0〜¥3,188 と広く最大の争点 |
| スリープ / コールドスタート | 採用 | 個人サイトの Books ページからの導線であり、訪問者を待たせない要件に直撃する |
| デプロイの手数 | 採用 | 「git push のみ」〜「OS からすべて自分」まで開く |
| Postgres の容量 | **除外** | 後述の試算で**全候補が10倍の余裕**を持つ。差がつかない |
| 独自ドメイン | **除外** | **全候補が対応**（Render は無料枠ですら対応）。差がつかない |

代わりに、判断に効いたため追加した基準が3つある。

| 追加基準 | 理由 |
|---|---|
| 非機能フェーズへの効き | 負荷試験・observability・障害の自作が成立するか |
| レイテンシ / リージョン | Railway は**東京リージョンが無く**シンガポールのみ |
| **撤退容易性** | Docker + Postgres なので**移設は数時間**。この決定は重くない |

**撤退容易性を基準に入れたことが、この選定の性格を決めている。**
覆すコストが数時間なら、完璧な結論を待つよりも、覆せる決定として早く出すほうが正しい。

### DB 容量を基準から外した根拠

書籍データを10万件規模で持つ計画があり「DB 容量が無料枠を圧迫する」ことを懸念していたが、
`books` のスキーマから試算した結果、**この懸念はほぼ杞憂だった。**

| 内訳 | サイズ |
|---|---|
| 本体 10万行（1行 ≈ 370B） | 37MB |
| PK + `index_books_on_isbn` | 7MB |
| **現行スキーマでの合計** | **≈ 45MB** |
| + 全文検索（pg_trgm GIN on title） | +30〜60MB |
| **+ ベクトル推薦（768次元 × 10万 + HNSW）** | **+450MB** |

> **上記はスキーマからの試算であり、実測値ではない。**

正確な言い方は「10万件だから容量が要る」ではなく **「推薦をやるなら要る」**。
Neon Free の 0.5GB を割るのはベクトルを持ったときだけで、それは非機能フェーズ
（2026年9月中旬以降）の、まだ着手が確定していない機能である。
**使うか分からない機能のために今から容量を買わない。**

---

## 最終候補

価格はすべて 2026-08-14 時点の一次情報（AWS Price List API / 各社公式ページ）に基づく。
USD/JPY = 159.39。

| | 構成 | USD/月 | JPY/月 |
|---|---|---|---|
| A | Lightsail 2GB + 同居 Postgres | $12.00 | ¥1,913 |
| B | Lightsail 1GB + Neon | $7.00 | ¥1,116 |
| **C（採用）** | **EC2 t4g.micro + Neon** | **$13.45** | **¥2,144** |

C の内訳: EC2 `$7.88`（$0.0108/h × 730）+ EBS gp3 20GB `$1.92`（$0.096/GB月）
+ パブリック IPv4 `$3.65`（$0.005/h）+ Neon Free `$0`

## なぜ最安の Lightsail ではなく EC2 か

Lightsail の中身は EC2 であり、EC2 + EBS + IPv4 + 転送量を定額バンドルしたものである。
EC2 で組み直すと IPv4 の $3.65 と EBS が別課金として表に出るぶん、**Lightsail のほうが安い。**
それでも C を採ったのは **Lightsail では使えないものが3つあるから。**

| | Lightsail | EC2 |
|---|---|---|
| **IAM インスタンスロール** | **非対応** → アクセスキーを `.env` に直置きするしかない | **対応** → アクセスキーを置かずに済む |
| **SSM Session Manager** | 非対応 | **対応** → 鍵も SSH トンネルも無しでシェルに入れる |
| VPC / サブネット / SG の設計 | ほぼ触れない | できる |
| CloudWatch メトリクス / ログ | 限定的 | フル |
| AWS Backup | 非対応（独自スナップショット） | 対応 |

とくに **SSM は「分散を減らす」方向に働く。**
個人サイトは SSH のために Cloudflare Tunnel + Access + サービストークンを構成しているが、
EC2 なら**シェルアクセスが IAM に一本化され、その一式が不要になる。**

**A との差額は月 $1.45（¥231）で、判断材料にならない額だった。**
そのため決め手を価格から「IAM ロール・SSM・VPC・CloudWatch を取れるか」に移した。

## なぜ EC2 に DB を同居させないか

同居させると 2GB が要る。`t4g.small` は $15.77/月で、EBS と IPv4 を足すと
**$22.3 になり Railway の $20 を上回る。**

**Neon を使うと箱から Postgres が消えて 1GB で足りる**ことが、C を現実的な価格に収めている。

## なぜ PaaS を採らなかったか

| 候補 | 却下理由 |
|---|---|
| **Railway（現状維持）** | **$20/月。**今回の見直しの出発点そのもの。加えて**東京リージョンが無く**シンガポールのみ（`asia-southeast1-eqsg3a`） |
| **Fly.io** | **Managed Postgres が $38/月から**（Basic / shared-2x / 1GB）。ストレージ別 $0.28/GB。自前 Postgres on volume なら $3.32 + storage だが、**手間は VPS と同等で値段は上** |
| **Render** | **無料 Postgres が作成30日で失効**（1GB固定・猶予14日）。無料 Web サービスは15分で停止し、復帰に約1分 |
| **Cloud Run（東京）** | 無料枠は大きい（200万req / 180,000 vCPU秒 / 360,000 GiB秒）が、**min-instances=0 ではリクエストごとにコールドスタート**。「訪問者を待たせない」要件と衝突。min-instances≧1 にすると無料枠の意味が消える |

## なぜ Cloudflare に載せないか

**Cloudflare は既にこの構成に入っている**（エッジ TLS・Tunnel）。
入らなかったのは compute と DB の層である。個人開発界隈での人気を踏まえ、層ごとに検討した。

| 層 | 却下理由 |
|---|---|
| **Workers** | V8 isolate + WASM のみで **Ruby ランタイムが無く Rails が動かない** |
| **D1** | SQLite であり **Workers バインディング経由でしか触れない**。Rails から Postgres プロトコルで接続できない。加えて `books.authors` は **PostgreSQL の配列型**で SQLite に素直に移らない |
| **Hyperdrive** | DB ではなく**プーラ / クエリキャッシュ**。かつ Workers 専用でオリジン上の Rails からは使えない |
| **Cloudflare の Postgres** | **自社製ではなく PlanetScale の再販**（2026-06-18 から Cloudflare 課金で作成可能）。サードパーティが1つ増える。PlanetScale は**無料枠が無く**最安 PS-5 非HA が $5/月 + ストレージ別 |
| **Containers** | **唯一の実候補だった**（Docker が動くため Rails も動く）。下記3点で却下 |

Containers を却下した理由。

- **既定 10分でスリープ、コールドスタート 1〜3秒** → 「訪問者を待たせない」要件と正面衝突
- **ディスクが全て ephemeral**（スナップショット未提供）→ **Postgres を同居させられない**
- Workers Paid **$5/月が必須**、`linux/amd64` のみ、配置は Cloudflare が自動選択で**東京の保証が無い**

**Cloudflare が賑わっているのは「エッジで動く JS/TS + D1/KV」の文脈**であり、
Rails + PostgreSQL + 常時起動という3条件のどれとも噛み合わない。
Shelfie を Cloudflare に載せることは**アプリを書き直すという別の意思決定**になる。

## なぜ他のマネージド DB を採らなかったか

| 候補 | 却下理由 |
|---|---|
| **Supabase Free** | **1週間無通信でプロジェクトが停止する。**閲覧者数人のサイトでは現実に起きる。東京リージョンがある点は評価した |
| **RDS `db.t4g.micro`** | 月 $12〜16 + ストレージ。EC2 と合わせて $26〜 になり **Railway の $20 を大きく超える** |
| **Aurora Serverless v2** | 最低 0.5 ACU の常時課金があり、この規模では割に合わない |
| **Lightsail Managed Database** | **$15/月から**（1GB / 40GB）。箱と合わせて $22〜 |

## なぜ VPS / 無料枠を採らなかったか

| 候補 | 却下理由 |
|---|---|
| **Oracle Cloud Always Free** | **¥0** で ARM 1,500 OCPU時 + 9,000 GB時/月、ブロック 200GB、外向き 10TB/月と破格。ただし **7日間 CPU/NW/メモリ利用率が20%未満だとインスタンスが回収される**（このアプリは確実に該当）。加えて ARM の capacity 待ちが常態化しており、**本番を置く先として信頼できない** |
| **国内 VPS（ConoHa / さくら / Xserver）** | 価格は魅力的（ConoHa 1GB ¥450/36ヶ月契約、さくら 1GB 東京 ¥908、Xserver 2GB ¥1,700）。**AWS に寄せる方針から外れ、請求先とアカウントが1つ増える。**ConoHa の ¥450 は36ヶ月契約が条件で、時間課金だと ¥1,065 になり価格優位も薄い |
| **Hetzner** | EU 主体。2024年からシンガポールがあるが**日本リージョンは無い** |

---

## コスト

| 項目 | USD/月 | JPY/月 |
|---|---|---|
| EC2 t4g.micro（オンデマンド） | $7.88 | ¥1,256 |
| EBS gp3 20GB | $1.92 | ¥306 |
| パブリック IPv4 | $3.65 | ¥582 |
| Neon Free | $0 | ¥0 |
| Cloudflare（Tunnel / Zero Trust 無料枠） | $0 | ¥0 |
| **合計** | **$13.45** | **¥2,144** |

**Railway の $20（¥3,188）に対して月 ¥1,044・年 ¥12,528 の削減。**

> AWS の請求は USD 建て。カード会社の海外事務手数料（1.6〜2.2% 程度）が上乗せされるため、
> 実質 ¥2,180〜2,190/月程度。為替が10円動くと月 ¥135 変動する。

## なぜ最初から RI を買わないか

**RI はインスタンス代（$7.88）にしか効かない。** EBS $1.92 と IPv4 $3.65 は対象外である。

| 購入方式 | インスタンス実効 | 総額/月 | 前払い |
|---|---|---|---|
| オンデマンド | $7.88 | **$13.45**（¥2,144） | $0 |
| **1年 No Upfront（standard）** | $4.96 | **$10.53**（¥1,679） | **$0** |
| 1年 All Upfront（standard） | $4.67 | $10.24（¥1,632） | $56 |
| 1年 No Upfront（convertible） | $6.21 | $11.78（¥1,878） | $0 |
| 3年 No Upfront（standard） | $3.43 | $9.00（¥1,435） | $0 |
| 3年 All Upfront（standard） | $2.97 | $8.54（¥1,361） | $107 |

**インスタンス単体では -37% だが、総額では -22% にしかならない。
月額の 41%（$5.57）が EBS と IPv4 という RI 対象外の固定費だから。**

Compute Savings Plans も確認した（1年 $0.0063〜0.0085/時、3年 $0.0041〜0.0061/時）。
**RI とほぼ同水準**だが、ファミリー・リージョンを跨いで効き Fargate / Lambda にも適用される。
個人サイトを EC2 に寄せる場合はこちらが有利になる。

それでも**まずオンデマンドで始める。** RI と Savings Plans は**使わなくても払う契約**で、
1年 No Upfront standard でも **$59.5（¥9,484）のコミット**が発生する。
**この構成にはまだ稼働実績が1ヶ月も無く、選んだインスタンスタイプが正しいかも実測前である**
（後述のメモリ懸念により `t4g.small` へ上げる可能性が残っている）。

RI は後からいつでも購入でき、**購入した瞬間から既存の稼働インスタンスに自動適用される**ため、
先に買う理由が存在しない。その1〜2ヶ月の差額は $6（¥900）で、
インスタンスタイプを固定しないための保険料として妥当である。

---

## 副次的な決定

### TLS をオリジンに置かない（Cloudflare Tunnel）

cloudflared の public hostname で `http://localhost:80` を公開し、TLS は Cloudflare エッジで終端する。

- **証明書がオリジンに存在しない** — Let's Encrypt の取得も Origin Certificate の配置・更新も不要
- **インバウンドを1つも開けない** — cloudflared は外向き接続のみ。Security Group に ingress ルールを書かない
- **Cloudflare IP レンジの保守が消える** — 個人サイトの CFN にある `CloudflareIpv4Cidrs` / `CloudflareIpv6Cidrs` 相当が不要
- **静的IP / Elastic IP が原理的に不要**（※外向き通信のため IPv4 自体は付ける）

却下した代替。

| 代替 | 却下理由 |
|---|---|
| kamal-proxy + Let's Encrypt（`ssl: true`） | 取得も更新も自動だが 80/443 の開放が必要。Cloudflare を orange のままにすると **"Always Use HTTPS" が HTTP-01 チャレンジを壊す** |
| Cloudflare Flexible SSL | 証明書は不要になるが **Cloudflare ↔ オリジンが平文**になる |

弱点は **cloudflared が単一障害点**になること。systemd の自動再起動で対処する。

### デプロイは Kamal 2.11 を使う

`Gemfile` に既に入っており（Rails 8 の標準）、`config/deploy.yml` は雛形のまま
（`servers: 192.168.0.1` / `registry: localhost:5555`）で未使用、`.kamal/hooks/` は全て `.sample`。

| | Kamal | docker compose 手運用（個人サイトの現行） |
|---|---|---|
| ゼロダウンタイム切替 | **標準** | 自前（`docker compose up -d` は瞬断する） |
| ロールバック | `kamal rollback` | 自前 |
| ログ / シェル | `kamal app logs` / `exec` | 自前 |

**個人サイトと構成を揃えることは目的にしない。**
「可能なら寄せる」程度の位置づけとし、寄せるのは Cloudflare 前段まで。
デプロイ機構は Kamal で改善する。**Kamal はサービスではなくツールなので外部依存は増えない。**

kamal-proxy は Cloudflare Tunnel の背後に置くため **`ssl` を指定せず HTTP-only** で動かし、
`forward_headers: true` を設定する（`ssl` 有効時は既定 false のため）。

### イメージは arm64 でビルドする

**`t4g` は Graviton（arm64）。** GHCR に arm64 イメージを push する必要がある。
GitHub Actions の arm64 ランナーを使う。x86 に落とす場合は `t3.micro`（$9.93/月）となり、
**`t4g.micro` より月 $2.05 高い。**

---

## 認識しているリスク

いずれも承知の上で採用している。

| リスク | 内容 | 対処 |
|---|---|---|
| **Neon に東京リージョンが無い** | 最寄りが `aws-ap-southeast-1`（シンガポール）。**RTT ≈ 70ms** が公開本棚のクエリ数だけ乗る | デプロイ後に**実測**し、非機能フェーズの改善対象として扱う |
| **Neon Free の 0.5GB 天井** | ベクトル推薦（+450MB）で必ず当たる | 当たった時点で「Neon Launch に課金」か「RDS / 同居に移す」を**新しい ADR で判断する** |
| **1GB でのゼロダウンタイム切替** | 切替中に Rails が2つ並ぶ。概算で 300MB×2 + proxy 30MB + OS/Docker 250MB ≈ **880MB / 1024MB** | スワップ 2GB を張る。OOM が出たら `t4g.small` に上げる |
| **cloudflared が単一障害点** | プロセス停止で全断 | systemd で自動再起動 |
| **箱1台＝単一障害点** | 冗長性が無い | **自分1人＋閲覧者数人に SLA は不要**という判断 |

> **上記のメモリ値は概算であり、実測値ではない。**
> Puma のワーカー数と実際の RSS を測ってから `t4g.small` への変更を判断する。

---

## 未決の論点

**この ADR では決めない。**

- **`.env.production` が [009](./009-authentication.md) 以前のまま**
  （`CLERK_SECRET_KEY` が残り、`GOOGLE_OAUTH_*` / `GITHUB_OAUTH_*` / `API_BASE_URL` / `FRONTEND_URL` が無い）
- **`config/cable.yml` の production に redis 設定が残っている**（ActionCable は未使用）
- 秘密の管理方法（SSM Parameter Store / Secrets Manager / `.env` 直置き）
- バックアップ方針（Neon 側に委ねる範囲と自前で取る範囲）
- **[008: ログ設計方針](./008-logging.md) と [docs/development/logging.md](../development/logging.md) に
  Railway 前提の記述が残っている。** ADR は歴史的記録なので 008 は書き換えず、
  `docs/development/` 側の更新を別 issue で行う

---

## 再検討のトリガー

**この決定は数時間で覆せる。** 以下が起きたら新しい番号で ADR を起票する。

- Neon Free の 0.5GB を超えたとき（= ベクトル推薦の着手時）
- シンガポール往復のレイテンシが実測で許容できないと分かったとき
- ユーザー登録を開放するとき
- 個人サイトを EC2 に寄せ、Savings Plans をまとめたほうが有利になったとき

---

## 関連ドキュメント

- [009: 認証方式](./009-authentication.md) — `COOKIE_DOMAIN` の親ドメイン共有制約はここに由来する
- [008: ログ設計方針](./008-logging.md) — Railway 前提の記述が残っている
- [技術スタック選定理由](../architecture/tech-stack.md)
- [システム構成](../architecture/overview.md)
- tofu-dev0123/life#99 — 選定の議論

### 価格の一次情報（2026-08-14 時点）

- AWS Price List `AmazonEC2 / ap-northeast-1`（オンデマンド・RI 全パターン）
- AWS Compute Savings Plan Price List `ap-northeast-1`
- https://aws.amazon.com/vpc/pricing/ （IPv4 $0.005/h）
- https://aws.amazon.com/lightsail/pricing/
- https://railway.com/pricing / https://docs.railway.com/reference/pricing/plans
- https://fly.io/docs/about/pricing/ / https://fly.io/docs/mpg/
- https://render.com/docs/free
- https://neon.com/pricing / https://neon.com/docs/introduction/regions
- https://supabase.com/pricing
- https://developers.cloudflare.com/containers/pricing/ / .../containers/platform-details/
- https://planetscale.com/pricing
- https://kamal-deploy.org/docs/configuration/proxy/
- USD/JPY = 159.39（2026-08-14 00:02 UTC・exchangerate-api.com）
