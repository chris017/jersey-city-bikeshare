import json
import time
import random
from datetime import datetime, timezone
from kafka import KafkaProducer

producer = KafkaProducer(
    bootstrap_servers='localhost:9092',
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

STATIONS = [
    {"id": 3183, "name": "Exchange Place"},
    {"id": 3186, "name": "Grove St PATH"},
    {"id": 3267, "name": "Morris Canal"},
    {"id": 3639, "name": "Harborside"},
]

BIKE_IDS = list(range(29000, 29050))

def generate_event():
    station = random.choice(STATIONS)
    return {
        "event_id": f"{int(time.time()*1000)}-{random.randint(1000,9999)}",
        "bike_id": random.choice(BIKE_IDS),
        "station_id": station["id"],
        "station_name": station["name"],
        "bikes_available": random.randint(0, 15),
        "docks_available": random.randint(0, 10),
        "event_timestamp": datetime.now(timezone.utc).isoformat()
    }

if __name__ == "__main__":
    print("Starting producer... sending events to topic 'bike_status_events'")
    while True:
        event = generate_event()
        producer.send("bike_status_events", value=event)
        print(f"Sent: {event}")
        time.sleep(1)
