# --- Warehouses ---

resource "snowflake_warehouse" "dbt_wh" {
  name           = "DBT_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60
  auto_resume    = true
  comment        = "Transformation/ETL workloads (dbt run, dbt test)"
}

resource "snowflake_warehouse" "bi_wh" {
  name           = "BI_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60
  auto_resume    = true
  comment        = "Reporting and BI queries (Jupyter, future PowerBI)"
}

resource "snowflake_warehouse" "ci_wh" {
  name           = "CI_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60
  auto_resume    = true
  comment        = "CI/CD pipeline runs (GitHub Actions)"
}

# --- Databases ---

resource "snowflake_database" "raw" {
  name    = "JERSEY_CITY_BIKESHARE"
  comment = "Central raw data source"
}

resource "snowflake_database" "dev" {
  name    = "JERSEY_CITY_BIKESHARE_DEV"
  comment = "Local development environment"
}

resource "snowflake_database" "ci" {
  name    = "JERSEY_CITY_BIKESHARE_CI"
  comment = "CI/CD pipeline runs, isolated from dev/prod"
}

resource "snowflake_database" "prod" {
  name    = "JERSEY_CITY_BIKESHARE_PROD"
  comment = "Production environment, read by BI/analytics"
}

# --- Role ---

resource "snowflake_account_role" "dbt_role" {
  name    = "DBT_ROLE"
  comment = "Role used by dbt for all transformation work"
}

# --- Grants: Role to User ---

resource "snowflake_grant_account_role" "dbt_role_to_user" {
  role_name = snowflake_account_role.dbt_role.name
  user_name = "CHRIS017"
}

# --- Grants: Warehouse usage ---

resource "snowflake_grant_privileges_to_account_role" "dbt_wh_usage" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "bi_wh_usage" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.bi_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_wh_usage" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.ci_wh.name
  }
}

# --- Grants: Database ownership/usage ---

resource "snowflake_grant_privileges_to_account_role" "raw_db_all" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["ALL"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.raw.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "dev_db_all" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["ALL"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dev.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "ci_db_all" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["ALL"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.ci.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "prod_db_all" {
  account_role_name = snowflake_account_role.dbt_role.name
  privileges        = ["ALL"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.prod.name
  }
}
