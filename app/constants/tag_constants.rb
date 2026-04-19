module TagConstants
  # サジェストAPI の返却上限。オートコンプリートで必要十分な件数。
  SUGGEST_LIMIT = 10

  # サジェストクエリの最大長。tags.name の DB 制約に合わせる。
  MAX_QUERY_LENGTH = 50
end
