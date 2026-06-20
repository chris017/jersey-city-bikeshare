# Jersey City Bikeshare — Data Pipeline & Analytics

An end-to-end data engineering project built on real Citibike trip data (Jersey City, NJ),
covering ingestion, transformation, orchestration, infrastructure-as-code, streaming, and analytics.

## Overview

This project implements a production-style analytics platform for a bike-sharing system:
raw trip data is ingested into a cloud data warehouse, transformed through a layered
(Bronze/Silver/Gold) architecture using dbt, validated and quarantined for data quality,
orchestrated with Airflow, provisioned entirely via Terraform, and complemented by a
real-time Kafka streaming pipeline for IoT-style bike status events.

**Batch data source:** [Citibike System Data](https://s3.amazonaws.com/tripdata/index.html) (Jersey City), August 2018 – March 2019 (~230,000 trips).
**Streaming data source:** simulated bike status events (producer/consumer pattern), since no public real-time feed with trip-level granularity exists for this system.

## Architecture

```
                                  ┌─────────────────────────────┐
                                  │   Terraform (IaC)           │
                                  │   4 databases · 3 warehouses│
                                  │   1 role · 8 grants         │
                                  └──────────────┬───────────────┘
                                                  │ provisions
                                                  ▼
Raw CSV (Citibike) → Snowflake Stage → COPY INTO → RAW (central source)
                                                          │
Kafka Producer → Topic → Kafka Consumer (micro-batch) ───┤
                                                          │
                                                          ▼
                                  dbt: Validation + Quarantine (Silver)
                                  ├── stg_citibike_trips_validated
                                  ├── stg_citibike_trips (valid only)
                                  ├── stg_citibike_trips_quarantine
                                  └── stg_bike_status_stream
                                                          │
                                                          ▼
                                  dbt: Marts — Star Schema (Gold)
                                  ├── dim_stations · dim_dates
                                  └── fct_trips (incremental, merge strategy)
                                                          │
                                                          ▼
                                  dbt: Aggregates (Gold)
                                  ├── agg_daily_summary · agg_station_ranking
                                  ├── agg_trips_per_user_type
                                  ├── agg_usage_patterns_by_hour
                                  └── agg_latest_station_status (from stream)
                                                          │
                                                          ▼
                          Orchestrated by Airflow (Cosmos) — Dev / CI / Prod isolated
                                                          │
                                                          ▼
                          Analysis & visualization (Jupyter: Plotly, Folium maps)
```

## Tech Stack

| Layer | Tool |
|---|---|
| Data Warehouse | Snowflake (4 isolated databases: raw, dev, ci, prod) |
| Compute | 3 dedicated warehouses (ETL, BI/reporting, CI) |
| Transformation | dbt Core |
| Streaming | Apache Kafka (producer/consumer, micro-batching) |
| Orchestration | Apache Airflow (via Astronomer Cosmos) |
| Infrastructure as Code | Terraform (`snowflakedb/snowflake` provider) |
| Containerization | Docker (Astro CLI, Kafka) |
| CI/CD | GitHub Actions (separate workflows for dbt and Kafka) |
| Analysis & Visualization | Python (pandas, Plotly, Folium) in Jupyter |
| Data Quality | dbt tests, custom validation/quarantine layer, monitoring tests |

## Repository Structure

This project spans two repositories, connected via a git submodule:

```
jersey-city-bikeshare              (this repo — orchestration, infra, CI/CD)
├── jersey_city_bikeshare_airflow/  # Astro/Airflow project: DAGs, Docker setup
│   └── include/jersey_city_bikeshare_dbt/   → submodule
├── jersey_city_bikeshare_dbt/      → submodule, see below
├── jersey_city_bikeshare_infra/    # Terraform: warehouses, databases, roles, grants
├── jersey_city_bikeshare_streaming/# Kafka producer/consumer, docker-compose
└── .github/workflows/              # dbt-ci.yml, kafka-ci.yml

jersey-city-bikeshare-dbt          (separate repo, single source of truth for dbt code)
└── models/, tests/, macros/, notebook/
```

The dbt project is referenced as a git submodule from both the repository root and the
Airflow `include/` directory, so the transformation code only ever lives in one place —
no manual copying between the standalone dbt project and the orchestration layer.

## Key Features

### Data modeling
- **Medallion architecture**: Raw → Staging (with validation) → Marts (core + aggregates)
- **Star schema**: one fact table (`fct_trips`) with two dimensions (`dim_stations`, `dim_dates`)
- **Incremental loading with merge strategy**: `fct_trips` uses `incremental_strategy='merge'`
  with a `unique_key`, supporting both inserts and updates (not just append)

### Data quality
- **Validation + quarantine layer**: rows failing business rules (invalid trip duration,
  start-after-end timestamps, missing stations, implausible birth years) are routed to a
  dedicated quarantine table instead of silently breaking downstream models
- **24 automated dbt tests**: uniqueness, null checks, referential integrity, and a custom
  monitoring test that fails if the quarantine rate exceeds 5% of total volume
- Caught and resolved three real data issues during development: a stale dimension table
  after an incremental load, a station with slightly drifting GPS coordinates over time, and
  a documented sentinel value (`birth_year = 1888`) used by Citibike for missing data

### Infrastructure & environments
- **Compute isolation**: three dedicated Snowflake warehouses (ETL, BI/reporting, CI) so
  transformation jobs, analytics queries, and CI runs never compete for the same compute
- **Dev / CI / Prod separation**: three isolated databases for transformed data, all reading
  from a single shared raw database — environments cannot interfere with each other
- **Infrastructure as Code**: all databases, warehouses, the service role, and every grant
  are defined in Terraform and fully reproducible (`terraform apply` from zero)

### Orchestration & CI/CD
- **Full pipeline orchestration**: every dbt model and test runs as an individual,
  dependency-aware Airflow task via Cosmos — no manual DAG wiring required
- **Two independent CI/CD pipelines**: one for the batch/dbt pipeline, one for the Kafka
  streaming pipeline (spins up a real Kafka broker as a GitHub Actions service container,
  produces test events, consumes them, and verifies they landed in Snowflake)
- **Production-like simulation**: two months of data were deliberately withheld and later
  loaded to simulate a real "new data arrives" pipeline run, confirming incremental
  processing end-to-end through Airflow

### Streaming
- **Kafka producer/consumer pipeline**: simulates real-time bike status events (station,
  bikes/docks available) at one event per second
- **Micro-batched consumer**: writes to Snowflake in batches (size- or time-triggered),
  tracking ingestion lag between event time and load time
- **Latest-status aggregate**: a dbt model surfaces the most recent known state per station,
  the kind of query a live operations dashboard would run

## Analytics Highlights

Full analysis with all charts and maps: [`jersey_city_bikeshare_insights.ipynb`](https://github.com/chris017/jersey-city-bikeshare-dbt/blob/main/notebook/jersey_city_bikeshare_insights.ipynb)

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
- ~0.03% of historical trips carry a known data-entry sentinel (`birth_year = 1888`), correctly
  isolated by the quarantine layer rather than polluting downstream aggregates

## Running This Project

### Clone with submodule
```bash
git clone --recurse-submodules https://github.com/chris017/jersey-city-bikeshare.git
```

### Infrastructure (Terraform)
```bash
cd jersey_city_bikeshare_infra
terraform init
terraform plan
terraform apply
```

### dbt
```bash
cd jersey_city_bikeshare_dbt
dbt deps
dbt run --target dev
dbt test --target dev
dbt docs generate && dbt docs serve
```

### Airflow (via Astro CLI)
```bash
cd jersey_city_bikeshare_airflow
astro dev start
# UI at http://localhost:8080
```

### Kafka streaming
```bash
cd jersey_city_bikeshare_streaming
docker-compose up -d
python3 producer.py    # terminal 1
python3 consumer.py    # terminal 2
```

### Notebook
```bash
cd jersey_city_bikeshare_dbt/notebook
jupyter notebook jersey_city_bikeshare_insights.ipynb
```

Each component requires its own `.env` file (not included, see `.gitignore`) with Snowflake
connection details and a key-pair authenticated private key — credentials are intentionally
excluded from this repository.

## CI/CD

Two GitHub Actions workflows run automatically on relevant pushes (and can be triggered manually):

- **`dbt-ci.yml`**: installs dbt, runs the full model graph and test suite against an isolated
  CI database/warehouse
- **`kafka-ci.yml`**: spins up a Kafka broker as a service container, runs a producer that emits
  a fixed batch of events, runs a consumer that writes them to Snowflake, and fails the build if
  fewer events arrive than expected

## Roadmap / Not Yet Covered

- Real CDC (Change Data Capture) from a live source database — not meaningfully simulatable
  with static historical CSV exports
- Remote Terraform state backend (currently local state; would move to a managed backend for
  true multi-person collaboration)
- A dedicated BI tool (Power BI / Looker) connected directly to the prod warehouse, as an
  alternative to the notebook-based analysis