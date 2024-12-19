output "lambda_jar_path" {
  value = local.lambda_jar_path
}

output "jar_hash" {
  value = fileexists(local.lambda_jar_path) ? filebase64sha256(local.lambda_jar_path) : timestamp()
}
