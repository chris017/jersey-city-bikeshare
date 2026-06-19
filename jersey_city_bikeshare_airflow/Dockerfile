FROM astrocrpublic.azurecr.io/runtime:3.2-5
# Separate virtuelle Umgebung für dbt, getrennt von Airflows eigenen Python-Paketen
RUN python -m venv /usr/local/airflow/dbt_venv && \
    /usr/local/airflow/dbt_venv/bin/pip install --no-cache-dir dbt-snowflake