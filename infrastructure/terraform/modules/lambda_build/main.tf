resource "null_resource" "build_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "cd ${path.root}/../../../../backend && ./gradlew build"
  }
}

locals {
  lambda_jar_path = "${path.root}/../../../../backend/build/libs/tides-be.jar"
}
