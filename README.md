# Jersey City Bikeshare — Data Pipeline & Analytics

An end-to-end data engineering project built on real Citibike trip data (Jersey City, NJ),
covering ingestion, transformation, orchestration, testing, and analytics.

## Overview

This project simulates a production-style analytics pipeline for a bike-sharing system:
raw trip data is ingested into a cloud data warehouse, transformed through a layered
(Bronze/Silver/Gold) architecture using dbt, orchestrated with Airflow, and explored
through a set of geospatial and time-series visualizations.

**Data source:** [Citibike System Data](https://s3.amazonaws.com/tripdata/index.html) (Jersey City), August 2018 – March 2019 (~230,000 trips).

## Architecture

```
Raw CSV (Citibike) → Snowflake Stage → COPY INTO → Raw Layer
                                                          │
                                                          ▼
                                              dbt: Staging (Silver)
                                                          │
                                                          ▼
                                    dbt: Marts — Star Schema (Gold)
                                    ├── dim_stations
                                    ├── dim_dates
                                    └── fct_trips (incremental)
                                                          │
                                                          ▼
                                    dbt: Aggregates (Gold)
                                    ├── agg_daily_summary
                                    ├── agg_station_ranking
                                    ├── agg_trips_per_user_type
                                    └── agg_usage_patterns_by_hour
                                                          │
                                                          ▼
                                  Orchestrated by Airflow (Cosmos)
                                                          │
                                                          ▼
                                  Analysis & visualization (Jupyter)
```

## Tech Stack

| Layer | Tool |
|---|---|
| Data Warehouse | Snowflake |
| Transformation | dbt Core |
| Orchestration | Apache Airflow (via Astronomer Cosmos) |
| Containerization | Docker (Astro CLI) |
| Analysis & Visualization | Python (pandas, Plotly, Folium) in Jupyter |
| Data Quality | dbt tests (uniqueness, not-null, referential integrity) |

## Repository Structure

```
jersey_city_bikeshare_dbt/        # dbt project: models, tests, docs, notebook
jersey_city_bikeshare_airflow/    # Astro/Airflow project: DAGs, dbt project copy, Docker setup
```

## Key Features

- **Medallion architecture**: Raw → Staging → Marts (core + aggregates), fully modeled with dbt
- **Star schema**: one fact table (`fct_trips`) with two dimensions (`dim_stations`, `dim_dates`)
- **Incremental loading**: `fct_trips` only processes new rows on each run, verified under a
  6x data volume increase (24,910 → 229,554 rows) with no measurable performance degradation
- **Automated data quality tests**: 14 dbt tests covering uniqueness, null checks, and referential
  integrity; caught and helped resolve two real data issues during development (a stale dimension
  table after an incremental load, and a station with slightly drifting GPS coordinates over time)
- **Full pipeline orchestration**: every dbt model and test runs as an individual, dependency-aware
  Airflow task via Cosmos — no manual DAG wiring required
- **Production-like simulation**: two months of data were deliberately withheld and later loaded
  to simulate a real "new data arrives" pipeline run, confirming incremental processing end-to-end

## Analytics Highlights

Full analysis with all charts and maps: [`jersey_city_bikeshare_insights.ipynb`](jersey_city_bikeshare_dbt/notebook/jersey_city_bikeshare_insights.ipynb)

### Two distinct user behaviors emerge clearly from the data

**Subscribers (~95% of all trips)** behave like commuters:
- Two sharp activity peaks on weekdays: 7–9 AM and 5–7 PM
- Short, tightly clustered trip durations (~4–5 minutes)
- Almost exclusively stay within the Jersey City system (cross-system rate: 0.026%)

**Customers (~5% of all trips)** behave like leisure/tourist users:
- Peak activity on Sunday, 10 AM–3 PM, with a secondary Saturday evening peak
- Longer, more widely distributed trip durations
- ~9x more likely to end a trip outside Jersey City (cross-system rate: 0.23%)

### Other findings
- **Grove St PATH** is by far the busiest station (~7,000 trips start+end), consistent with its
  role as a transit hub — further supporting the commuter hypothesis
- A small number of stations are geographically located in Manhattan/Brooklyn (the Citibike network
  is technically interconnected), but cross-system trips account for only 0.037% of all trips overall

## Running This Project

### dbt
```bash
cd jersey_city_bikeshare_dbt
dbt deps
dbt run
dbt test
dbt docs generate && dbt docs serve
```

### Airflow (via Astro CLI)
```bash
cd jersey_city_bikeshare_airflow
astro dev start
# UI at http://localhost:8080
```

### Notebook
```bash
cd jersey_city_bikeshare_dbt/notebook
jupyter notebook jersey_city_bikeshare_insights.ipynb
```

Requires a `.env` file (not included, see `.gitignore`) with Snowflake connection details and a
key-pair authenticated private key — credentials are intentionally excluded from this repository.

## Roadmap / Not Yet Covered

- Streaming ingestion (Kafka / Pub/Sub) for real-time IoT-style bike status data
- Infrastructure as Code (Terraform) for Snowflake resource management
- CI/CD pipeline (e.g. GitHub Actions running `dbt test` on every push)
