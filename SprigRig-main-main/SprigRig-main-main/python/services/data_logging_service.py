import asyncio
import logging
import aiosqlite
from datetime import datetime, timedelta
from typing import List, Optional
from config import Config
from services.simulator_service import SensorSimulator

logger = logging.getLogger(__name__)

class DataLoggingService:
    """
    Polls sensors (real or simulated) and logs to database.
    """
    
    def __init__(self, zone_id: int):
        self.zone_id = zone_id
        self.db_path = Config.DB_PATH
        
        if Config.HARDWARE_MODE == 'simulate':
            self.source = SensorSimulator(zone_id)
        # elif Config.HARDWARE_MODE == 'replay':
        #     self.source = ReplayService(zone_id)
        else:
            # self.source = RealHardwareService(zone_id)
            self.source = SensorSimulator(zone_id) # Fallback for now until RealHardwareService is implemented
            
    async def poll_and_log(self):
        """
        Poll all sensors for zone and log readings.
        Called on interval by scheduler.
        """
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM sensors WHERE zone_id = ?", (self.zone_id,)) as cursor:
                sensors = await cursor.fetchall()
        
        for sensor in sensors:
            if not sensor['enabled']:
                continue
            
            # Determine reading types based on sensor type
            # This mapping should ideally be in a central place or DB
            reading_types = self._get_reading_types_for_sensor(sensor['sensor_type'])
            
            for reading_type in reading_types:
                try:
                    if Config.HARDWARE_MODE == 'simulate':
                        value = self.source.get_reading(
                            sensor['sensor_type'], 
                            reading_type
                        )
                    else:
                        # Placeholder for real hardware
                        value = 0.0 
                    
                    await self._log_sensor_reading(
                        sensor_id=sensor['id'],
                        reading_type=reading_type,
                        value=value
                    )
                    
                except Exception as e:
                    logger.error(f"Failed to read {sensor['name']}: {e}")
    
    async def backfill_historical(self, days: int = 7):
        """
        Generate historical data for demo/testing.
        Only works in simulate mode.
        """
        if Config.HARDWARE_MODE != 'simulate':
            raise ValueError("Backfill only available in simulate mode")
        
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM sensors WHERE zone_id = ?", (self.zone_id,)) as cursor:
                sensors = await cursor.fetchall()
        
        end = datetime.now()
        start = end - timedelta(days=days)
        
        for sensor in sensors:
            reading_types = self._get_reading_types_for_sensor(sensor['sensor_type'])
            
            for reading_type in reading_types:
                readings = self.source.generate_historical_data(
                    sensor['sensor_type'],
                    reading_type,
                    start,
                    end,
                    interval_minutes=5
                )
                
                # Batch insert for performance
                await self._batch_log_sensor_readings(sensor['id'], readings)

    def _get_reading_types_for_sensor(self, sensor_type: str) -> List[str]:
        # Simple mapping for now
        from .simulator_service import SENSOR_PROFILES
        return SENSOR_PROFILES.get(sensor_type, {}).get('readings', [])

    async def _log_sensor_reading(self, sensor_id: int, reading_type: str, value: float, timestamp: int = None):
        if timestamp is None:
            timestamp = int(datetime.now().timestamp())
            
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute("""
                INSERT INTO sensor_readings (sensor_id, reading_type, value, timestamp)
                VALUES (?, ?, ?, ?)
            """, (sensor_id, reading_type, value, timestamp))
            await db.commit()

    async def _batch_log_sensor_readings(self, sensor_id: int, readings: List):
        async with aiosqlite.connect(self.db_path) as db:
            data = [(sensor_id, r.reading_type, r.value, int(r.timestamp.timestamp())) for r in readings]
            await db.executemany("""
                INSERT INTO sensor_readings (sensor_id, reading_type, value, timestamp)
                VALUES (?, ?, ?, ?)
            """, data)
            await db.commit()
