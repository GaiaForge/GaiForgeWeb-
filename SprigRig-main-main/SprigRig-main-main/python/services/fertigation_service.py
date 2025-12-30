import aiosqlite
from pydantic import BaseModel
from typing import List, Optional
import time
import asyncio
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Models
class FertigationConfig(BaseModel):
    id: Optional[int]
    zone_id: int
    enabled: bool = False
    reservoir_liters: Optional[float]
    mixing_time_seconds: int = 300
    check_interval_seconds: int = 900
    dosing_mode: str = 'auto'
    manual_ph_min: Optional[float]
    manual_ph_max: Optional[float]
    manual_ec_min: Optional[float]
    manual_ec_max: Optional[float]
    use_recipe_targets: bool = True
    max_dose_ml: float = 50.0
    max_doses_per_hour: int = 4
    created_at: Optional[int]
    updated_at: Optional[int]

class Pump(BaseModel):
    id: Optional[int]
    zone_id: int
    name: str
    pump_type: str
    relay_channel: int
    relay_module_address: int
    ml_per_second: float
    enabled: bool = True
    created_at: Optional[int]
    updated_at: Optional[int]

class Probe(BaseModel):
    id: Optional[int]
    zone_id: int
    probe_type: str
    hub_address: int
    input_channel: int
    input_type: str
    range_min: float
    range_max: float
    calibration_offset: float = 0
    calibration_slope: float = 1
    enabled: bool = True
    created_at: Optional[int]
    updated_at: Optional[int]

class Reading(BaseModel):
    id: Optional[int]
    zone_id: int
    probe_id: int
    value: float
    temperature: Optional[float]
    timestamp: int

class DoseEvent(BaseModel):
    id: Optional[int]
    zone_id: int
    pump_id: int
    dose_ml: float
    duration_seconds: float
    trigger: str
    reading_before: Optional[float]
    reading_after: Optional[float]
    timestamp: int

class FertigationService:
    def __init__(self, db_path: str):
        self.db_path = db_path

    async def get_config(self, zone_id: int) -> Optional[FertigationConfig]:
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM fertigation_config WHERE zone_id = ?", (zone_id,)) as cursor:
                row = await cursor.fetchone()
                if row:
                    return FertigationConfig(**dict(row))
        return None

    async def update_config(self, zone_id: int, config: FertigationConfig):
        async with aiosqlite.connect(self.db_path) as db:
            async with db.execute("SELECT 1 FROM fertigation_config WHERE zone_id = ?", (zone_id,)) as cursor:
                exists = await cursor.fetchone()
            
            now = int(time.time())
            if exists:
                await db.execute("""
                    UPDATE fertigation_config SET 
                        enabled=?, reservoir_liters=?, mixing_time_seconds=?, check_interval_seconds=?,
                        dosing_mode=?, manual_ph_min=?, manual_ph_max=?, manual_ec_min=?, manual_ec_max=?,
                        use_recipe_targets=?, max_dose_ml=?, max_doses_per_hour=?, updated_at=?
                    WHERE zone_id=?
                """, (
                    config.enabled, config.reservoir_liters, config.mixing_time_seconds, config.check_interval_seconds,
                    config.dosing_mode, config.manual_ph_min, config.manual_ph_max, config.manual_ec_min, config.manual_ec_max,
                    config.use_recipe_targets, config.max_dose_ml, config.max_doses_per_hour, now, zone_id
                ))
            else:
                await db.execute("""
                    INSERT INTO fertigation_config (
                        zone_id, enabled, reservoir_liters, mixing_time_seconds, check_interval_seconds,
                        dosing_mode, manual_ph_min, manual_ph_max, manual_ec_min, manual_ec_max,
                        use_recipe_targets, max_dose_ml, max_doses_per_hour, created_at, updated_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (
                    zone_id, config.enabled, config.reservoir_liters, config.mixing_time_seconds, config.check_interval_seconds,
                    config.dosing_mode, config.manual_ph_min, config.manual_ph_max, config.manual_ec_min, config.manual_ec_max,
                    config.use_recipe_targets, config.max_dose_ml, config.max_doses_per_hour, now, now
                ))
            await db.commit()

    async def get_pumps(self, zone_id: int) -> List[Pump]:
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM fertigation_pumps WHERE zone_id = ?", (zone_id,)) as cursor:
                rows = await cursor.fetchall()
                return [Pump(**dict(row)) for row in rows]

    async def add_pump(self, zone_id: int, pump: Pump) -> int:
        async with aiosqlite.connect(self.db_path) as db:
            now = int(time.time())
            cursor = await db.execute("""
                INSERT INTO fertigation_pumps (
                    zone_id, name, pump_type, relay_channel, relay_module_address, ml_per_second, enabled, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                zone_id, pump.name, pump.pump_type, pump.relay_channel, pump.relay_module_address, 
                pump.ml_per_second, pump.enabled, now, now
            ))
            await db.commit()
            return cursor.lastrowid

    async def update_pump(self, pump_id: int, pump: Pump):
        async with aiosqlite.connect(self.db_path) as db:
            now = int(time.time())
            await db.execute("""
                UPDATE fertigation_pumps SET 
                    name=?, pump_type=?, relay_channel=?, relay_module_address=?, ml_per_second=?, enabled=?, updated_at=?
                WHERE id=?
            """, (
                pump.name, pump.pump_type, pump.relay_channel, pump.relay_module_address, 
                pump.ml_per_second, pump.enabled, now, pump_id
            ))
            await db.commit()

    async def delete_pump(self, pump_id: int):
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute("DELETE FROM fertigation_pumps WHERE id=?", (pump_id,))
            await db.commit()

    async def get_probes(self, zone_id: int) -> List[Probe]:
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM fertigation_probes WHERE zone_id = ?", (zone_id,)) as cursor:
                rows = await cursor.fetchall()
                return [Probe(**dict(row)) for row in rows]

    async def add_probe(self, zone_id: int, probe: Probe) -> int:
        async with aiosqlite.connect(self.db_path) as db:
            now = int(time.time())
            cursor = await db.execute("""
                INSERT INTO fertigation_probes (
                    zone_id, probe_type, hub_address, input_channel, input_type, range_min, range_max, 
                    calibration_offset, calibration_slope, enabled, created_at, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                zone_id, probe.probe_type, probe.hub_address, probe.input_channel, probe.input_type,
                probe.range_min, probe.range_max, probe.calibration_offset, probe.calibration_slope,
                probe.enabled, now, now
            ))
            await db.commit()
            return cursor.lastrowid

    async def calibrate_probe(self, probe_id: int, calibration_offset: float, calibration_slope: float):
        async with aiosqlite.connect(self.db_path) as db:
            now = int(time.time())
            await db.execute("""
                UPDATE fertigation_probes SET 
                    calibration_offset=?, calibration_slope=?, updated_at=?
                WHERE id=?
            """, (calibration_offset, calibration_slope, now, probe_id))
            await db.commit()

    async def get_current_targets(self, zone_id: int) -> dict:
        """
        Get active targets from recipe or manual settings.
        Returns: {ph_min, ph_max, ec_min, ec_max, nutrient_ratios, source}
        """
        config = await self.get_config(zone_id)
        if not config:
            return {}

        if config.use_recipe_targets:
            # Check for active recipe phase
            async with aiosqlite.connect(self.db_path) as db:
                db.row_factory = aiosqlite.Row
                async with db.execute("""
                    SELECT rp.* 
                    FROM zone_crops zc
                    JOIN recipe_phases rp ON zc.current_phase_id = rp.id
                    WHERE zc.zone_id = ? AND zc.is_active = 1
                """, (zone_id,)) as cursor:
                    phase = await cursor.fetchone()
                    
                    if phase and phase['fertigation_enabled']:
                        return {
                            'ph_min': phase['target_ph_min'],
                            'ph_max': phase['target_ph_max'],
                            'ec_min': phase['target_ec_min'],
                            'ec_max': phase['target_ec_max'],
                            'nutrient_a': phase['nutrient_a_ml_per_liter'],
                            'nutrient_b': phase['nutrient_b_ml_per_liter'],
                            'nutrient_c': phase['nutrient_c_ml_per_liter'],
                            'calmag': phase['calmag_ml_per_liter'],
                            'silica': phase['silica_ml_per_liter'],
                            'enzymes': phase['enzymes_ml_per_liter'],
                            'source': 'recipe'
                        }
        
        # Fall back to manual settings
        return {
            'ph_min': config.manual_ph_min,
            'ph_max': config.manual_ph_max,
            'ec_min': config.manual_ec_min,
            'ec_max': config.manual_ec_max,
            'source': 'manual'
        }

    # Hardware Interaction Placeholders
    async def read_ph(self, zone_id: int) -> float:
        # TODO: Implement actual hardware reading
        # 1. Get pH probe config for zone
        # 2. Read from Modbus/ADC
        # 3. Apply calibration
        return 6.0 # Mock value

    async def read_ec(self, zone_id: int) -> float:
        # TODO: Implement actual hardware reading
        return 1.2 # Mock value

    async def read_temperature(self, zone_id: int) -> float:
        # TODO: Implement actual hardware reading
        return 22.5 # Mock value

    async def dose_pump(self, pump_id: int, ml: float, trigger: str):
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM fertigation_pumps WHERE id = ?", (pump_id,)) as cursor:
                row = await cursor.fetchone()
                if not row:
                    logger.error(f"Pump {pump_id} not found")
                    return
                pump = Pump(**dict(row))

        duration_seconds = ml / pump.ml_per_second
        logger.info(f"Dosing {ml}ml with pump {pump.name} for {duration_seconds}s (Trigger: {trigger})")
        
        # TODO: Implement actual relay control
        # await run_relay(pump.relay_module_address, pump.relay_channel, duration_seconds)
        
        # Log dose
        async with aiosqlite.connect(self.db_path) as db:
            now = int(time.time())
            await db.execute("""
                INSERT INTO fertigation_dose_log (
                    zone_id, pump_id, dose_ml, duration_seconds, trigger, timestamp
                ) VALUES (?, ?, ?, ?, ?, ?)
            """, (pump.zone_id, pump.id, ml, duration_seconds, trigger, now))
            await db.commit()

    async def run_ph_control_loop(self, zone_id: int):
        config = await self.get_config(zone_id)
        if not config or not config.enabled:
            return

        targets = await self.get_current_targets(zone_id)
        if not targets.get('ph_min') or not targets.get('ph_max'):
            logger.warning(f"No pH targets found for zone {zone_id}")
            return

        current_ph = await self.read_ph(zone_id)
        logger.info(f"Zone {zone_id} pH: {current_ph} (Target: {targets['ph_min']} - {targets['ph_max']})")
        
        # Logic for dosing pH Up/Down
        if current_ph < targets['ph_min']:
            # Dose pH Up
            # Calculate amount...
            pass
        elif current_ph > targets['ph_max']:
            # Dose pH Down
            pass

    async def run_ec_control_loop(self, zone_id: int):
        config = await self.get_config(zone_id)
        if not config or not config.enabled:
            return

        targets = await self.get_current_targets(zone_id)
        if not targets.get('ec_min'): # Assuming min is the primary target for dosing
            logger.warning(f"No EC targets found for zone {zone_id}")
            return

        current_ec = await self.read_ec(zone_id)
        logger.info(f"Zone {zone_id} EC: {current_ec} (Target: {targets['ec_min']})")
        
        # Logic for dosing nutrients
        if current_ec < targets['ec_min']:
            # Dose nutrients
            pass

    async def get_readings(self, zone_id: int, hours: int = 24) -> List[Reading]:
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            cutoff = int(time.time()) - (hours * 3600)
            async with db.execute("""
                SELECT * FROM fertigation_readings 
                WHERE zone_id = ? AND timestamp > ? 
                ORDER BY timestamp DESC
            """, (zone_id, cutoff)) as cursor:
                rows = await cursor.fetchall()
                return [Reading(**dict(row)) for row in rows]

    async def get_dose_history(self, zone_id: int, hours: int = 24) -> List[DoseEvent]:
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            cutoff = int(time.time()) - (hours * 3600)
            async with db.execute("""
                SELECT * FROM fertigation_dose_log 
                WHERE zone_id = ? AND timestamp > ? 
                ORDER BY timestamp DESC
            """, (zone_id, cutoff)) as cursor:
                rows = await cursor.fetchall()
                return [DoseEvent(**dict(row)) for row in rows]
