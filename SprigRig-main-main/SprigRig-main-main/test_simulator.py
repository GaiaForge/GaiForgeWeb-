import asyncio
import os
import sys

# Add python directory to path
sys.path.append(os.path.join(os.getcwd(), 'python'))

from services.simulator_service import SensorSimulator
from services.data_logging_service import DataLoggingService
from config import Config

async def test_simulator():
    print("Testing Sensor Simulator...")
    sim = SensorSimulator(zone_id=1)
    
    # Test reading generation
    temp = sim.get_reading('dht22', 'temperature')
    hum = sim.get_reading('dht22', 'humidity')
    print(f"Generated Reading - Temp: {temp}°C, Humidity: {hum}%")
    
    assert 10.0 <= temp <= 40.0
    assert 20.0 <= hum <= 95.0
    
    print("Simulator test passed.")

async def test_data_logging():
    print("Testing Data Logging Service...")
    # Mock DB path for testing
    Config.DB_PATH = 'test_sprigrig.db'
    
    # Create dummy DB and table
    import aiosqlite
    async with aiosqlite.connect(Config.DB_PATH) as db:
        await db.execute("""
            CREATE TABLE IF NOT EXISTS sensors (
                id INTEGER PRIMARY KEY,
                zone_id INTEGER,
                name TEXT,
                sensor_type TEXT,
                enabled INTEGER
            )
        """)
        await db.execute("""
            CREATE TABLE IF NOT EXISTS sensor_readings (
                id INTEGER PRIMARY KEY,
                sensor_id INTEGER,
                reading_type TEXT,
                value REAL,
                timestamp INTEGER
            )
        """)
        # Insert dummy sensor
        await db.execute("INSERT INTO sensors (zone_id, name, sensor_type, enabled) VALUES (1, 'Test DHT', 'dht22', 1)")
        await db.commit()
    
    service = DataLoggingService(zone_id=1)
    await service.poll_and_log()
    
    # Verify log
    async with aiosqlite.connect(Config.DB_PATH) as db:
        async with db.execute("SELECT * FROM sensor_readings") as cursor:
            rows = await cursor.fetchall()
            print(f"Logged {len(rows)} readings.")
            assert len(rows) > 0
            
    # Test backfill
    print("Testing Backfill...")
    await service.backfill_historical(days=1)
    
    async with aiosqlite.connect(Config.DB_PATH) as db:
        async with db.execute("SELECT count(*) FROM sensor_readings") as cursor:
            count = (await cursor.fetchone())[0]
            print(f"Total readings after backfill: {count}")
            assert count > 100
            
    print("Data logging test passed.")
    
    # Cleanup
    if os.path.exists(Config.DB_PATH):
        os.remove(Config.DB_PATH)

async def main():
    await test_simulator()
    await test_data_logging()

if __name__ == "__main__":
    asyncio.run(main())
