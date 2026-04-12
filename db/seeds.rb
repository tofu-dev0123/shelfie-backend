# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

tag_names = [
  "AI", "Apache Spark", "AWS", "Azure",
  "C", "C++",
  "DevOps", "Django", "Docker",
  "Firebase", "FPGA", "Flutter",
  "GCP", "Go",
  "Haskell",
  "Java", "JavaScript",
  "Kotlin", "Kubernetes",
  "Linux", "LLM",
  "MATLAB", "MongoDB", "MySQL",
  "Next.js",
  "PHP", "PostgreSQL", "PyTorch", "Python",
  "R", "Rails", "React", "React Native", "Redis", "Ruby", "Rust",
  "Scala", "scikit-learn", "Spring", "SQL", "Swift",
  "TensorFlow", "Terraform", "TypeScript",
  "UI/UX", "Unity", "Unreal Engine",
  "Vue",
  "アーキテクチャ", "アジャイル", "アルゴリズム", "暗号理論",
  "オブジェクト指向", "組み込み",
  "関数型プログラミング", "キャリア", "機械学習", "強化学習", "グラフィックス", "ゲーム開発", "コンピュータビジョン",
  "システム設計", "自然言語処理", "信号処理", "数学", "深層学習", "生成AI", "セキュリティ",
  "データエンジニアリング", "データサイエンス", "データ構造", "テスト", "統計",
  "ネットワーク",
  "バックエンド", "ビジネス", "フロントエンド",
  "マネジメント", "モバイル",
  "ロボティクス"
]

tag_names.each do |name|
  Tag.find_or_create_by!(name: name)
end
