terraform {
  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 0.95"
    }
  }
}

provider "snowflake" {
  organization_name = var.snowflake_organization
  account_name       = var.snowflake_account
  user               = var.snowflake_user
  authenticator      = "SNOWFLAKE_JWT"
  private_key        = file(var.snowflake_private_key_path)
  role               = "ACCOUNTADMIN"
}
