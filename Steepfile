D = Steep::Diagnostic

target :models do
  signature "sig"

  check "app/models"

  configure_code_diagnostics(D::Ruby.default)
end

target :rest do
  signature "sig"

  check "app/controllers"
  check "lib"

  ignore "db/schema.rb"
  ignore "db/migrate"
  ignore "bin"
  ignore "vendor"

  configure_code_diagnostics(D::Ruby.lenient)
end
