resource "aws_secretsmanager_secret" "db_secret" {
  name        = var.secret_name
  description = "Database credentials for Flask app"
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    DB_HOST = var.db_host
    DB_USER = var.db_username
    DB_PASS = var.db_password
    DB_NAME = var.db_name
  })
}
