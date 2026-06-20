import json
import os
import sys
from cryptography.hazmat.primitives import serialization
import snowflake.connector
from kafka import KafkaConsumer

EXPECTED_EVENTS = 25

with open(os.environ["SNOWFLAKE_PRIVATE_KEY_PATH"], "rb") as key_file:
    p_key = serialization.load_pem_private_key(key_file.read(), password=None)

pkb = p_key.private_bytes(
    encoding=serialization.Encoding.DER,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption(),
)

conn = snowflake.connector.connect(
    account=os.environ["SNOWFLAKE_ACCOUNT"],
    user=os.environ["SNOWFLAKE_USER"],
    private_key=pkb,
    role=os.environ["SNOWFLAKE_ROLE"],
    warehouse=os.environ["SNOWFLAKE_WAREHOUSE"],
    database=os.environ["SNOWFLAKE_DATABASE"],
    schema="raw",
)
cursor = conn.cursor()

cursor.execute("""
    CREATE TABLE IF NOT EXISTS raw_bike_status_stream (
        event_id STRING,
        bike_id NUMBER,
        station_id NUMBER,
        station_name STRING,
        bikes_available NUMBER,
        docks_available NUMBER,
        event_timestamp TIMESTAMP_NTZ,
        loaded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
    )
""")
print("Table raw_bike_status_stream ready.")

consumer = KafkaConsumer(
    "bike_status_events",
    bootstrap_servers="localhost:9092",
    value_deserializer=lambda v: json.loads(v.decode("utf-8")),
    auto_offset_reset="earliest",
    group_id="ci-snowflake-writer",
    consumer_timeout_ms=10000,  # gibt nach 10s ohne neue Nachrichten auf
)

rows = []
for message in consumer:
    e = message.value
    rows.append((
        e["event_id"], e["bike_id"], e["station_id"], e["station_name"],
        e["bikes_available"], e["docks_available"], e["event_timestamp"],
    ))

if rows:
    cursor.executemany(
        """
        INSERT INTO raw_bike_status_stream
        (event_id, bike_id, station_id, station_name, bikes_available, docks_available, event_timestamp)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
        """,
        rows,
    )
    conn.commit()

print(f"CI consumer: wrote {len(rows)} rows to Snowflake.")

if len(rows) < EXPECTED_EVENTS:
    print(f"ERROR: expected at least {EXPECTED_EVENTS} events, got {len(rows)}")
    sys.exit(1)

print("CI consumer finished successfully.")