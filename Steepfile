D = Steep::Diagnostic

target :app do
  signature "sig"

  check "app/models"
  check "app/controllers"
  check "lib"

  ignore "db/schema.rb"
  ignore "db/migrate"
  ignore "bin"
  ignore "vendor"

  configure_code_diagnostics(D::Ruby.lenient)
end
