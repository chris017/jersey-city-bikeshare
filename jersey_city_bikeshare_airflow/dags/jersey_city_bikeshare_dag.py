import os
from datetime import datetime
from cosmos import DbtDag, ProjectConfig, ProfileConfig, ExecutionConfig

profile_config = ProfileConfig(
    profile_name="jersey_city_bikeshare",
    target_name="dev",
    profiles_yml_filepath="/usr/local/airflow/include/dbt_profiles/profiles.yml",
)

project_config = ProjectConfig(
    "/usr/local/airflow/include/jersey_city_bikeshare_dbt",
)

execution_config = ExecutionConfig(
    dbt_executable_path="/usr/local/airflow/dbt_venv/bin/dbt",
)

jersey_city_bikeshare_dag = DbtDag(
    project_config=project_config,
    profile_config=profile_config,
    execution_config=execution_config,
    schedule="@daily",
    start_date=datetime(2024, 1, 1),
    catchup=False,
    dag_id="jersey_city_bikeshare_pipeline",
)
