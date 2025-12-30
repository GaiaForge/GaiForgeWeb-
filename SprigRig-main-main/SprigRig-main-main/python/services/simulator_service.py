import math
import random
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass
from config import Config

@dataclass
class SimulatedReading:
    sensor_id: int
    reading_type: str
    value: float
    timestamp: datetime

SENSOR_PROFILES = {
    'dht22': {
        'readings': ['temperature', 'humidity'],
        'temperature': {
            'base': 24.0,
            'unit': '°C',
            'min': 10.0,
            'max': 40.0,
            'noise': 0.3,
            'diurnal_amplitude': 4.0,  # Day/night swing
            'diurnal_phase': 14,       # Peak hour (2 PM)
        },
        'humidity': {
            'base': 60.0,
            'unit': '%',
            'min': 20.0,
            'max': 95.0,
            'noise': 2.0,
            'diurnal_amplitude': 15.0,  # Inverse of temp
            'diurnal_phase': 4,         # Peak hour (4 AM)
        },
    },
    
    'bme280': {
        'readings': ['temperature', 'humidity', 'pressure'],
        'temperature': {
            'base': 24.0,
            'unit': '°C',
            'min': 10.0,
            'max': 40.0,
            'noise': 0.2,
            'diurnal_amplitude': 4.0,
            'diurnal_phase': 14,
        },
        'humidity': {
            'base': 60.0,
            'unit': '%',
            'min': 20.0,
            'max': 95.0,
            'noise': 1.5,
            'diurnal_amplitude': 15.0,
            'diurnal_phase': 4,
        },
        'pressure': {
            'base': 1013.25,
            'unit': 'hPa',
            'min': 980.0,
            'max': 1040.0,
            'noise': 0.5,
            'drift_per_hour': 0.1,  # Slow atmospheric drift
        },
    },
    
    'bme680': {
        'readings': ['temperature', 'humidity', 'pressure', 'gas_resistance'],
        # Inherits from bme280, plus:
        'gas_resistance': {
            'base': 50000.0,
            'unit': 'Ω',
            'min': 10000.0,
            'max': 500000.0,
            'noise': 5000.0,
        },
    },
    
    'soil_moisture': {
        'readings': ['moisture'],
        'moisture': {
            'base': 65.0,
            'unit': '%',
            'min': 0.0,
            'max': 100.0,
            'noise': 2.0,
            'decay_per_hour': 0.5,      # Dries out slowly
            'irrigation_boost': 30.0,    # Jump after watering
        },
    },
    
    'ph_sensor': {
        'readings': ['ph'],
        'ph': {
            'base': 6.0,
            'unit': 'pH',
            'min': 0.0,
            'max': 14.0,
            'noise': 0.05,
            'drift_per_hour': 0.02,     # Slow drift up (typical)
            'dose_effect': -0.3,         # pH down dose effect
        },
    },
    
    'ec_sensor': {
        'readings': ['ec'],
        'ec': {
            'base': 1.8,
            'unit': 'mS/cm',
            'min': 0.0,
            'max': 5.0,
            'noise': 0.05,
            'drift_per_hour': -0.01,    # Slow decline as plants uptake
            'dose_effect': 0.2,          # Nutrient dose effect
        },
    },
    
    'light_sensor': {
        'readings': ['light_intensity', 'par'],
        'light_intensity': {
            'base': 0.0,  # Controlled by light schedule
            'unit': 'lux',
            'min': 0.0,
            'max': 100000.0,
            'noise': 50.0,
            'lights_on_value': 45000.0,
            'lights_off_value': 0.0,
        },
        'par': {
            'base': 0.0,
            'unit': 'µmol/m²/s',
            'min': 0.0,
            'max': 2000.0,
            'noise': 5.0,
            'lights_on_value': 800.0,
            'lights_off_value': 0.0,
        },
    },
    
    'water_level': {
        'readings': ['water_level'],
        'water_level': {
            'base': 80.0,
            'unit': '%',
            'min': 0.0,
            'max': 100.0,
            'noise': 1.0,
            'consumption_per_hour': 0.5,  # Slow decline
            'refill_target': 95.0,
        },
    },
    
    'co2_sensor': {
        'readings': ['co2'],
        'co2': {
            'base': 800.0,
            'unit': 'ppm',
            'min': 300.0,
            'max': 2000.0,
            'noise': 20.0,
            'lights_on_target': 1200.0,   # Supplemented during day
            'lights_off_target': 450.0,   # Natural at night
        },
    },
    
    'pressure_sensor': {
        'readings': ['pressure'],
        'pressure': {
            'base': 1013.25,
            'unit': 'hPa',
            'min': 980.0,
            'max': 1040.0,
            'noise': 0.3,
            'drift_per_hour': 0.05,
        },
    },
    
    'flow_rate': {
        'readings': ['flow_rate'],
        'flow_rate': {
            'base': 0.0,  # Only non-zero during irrigation
            'unit': 'L/min',
            'min': 0.0,
            'max': 20.0,
            'noise': 0.1,
            'active_value': 4.5,
        },
    },
}

class SensorSimulator:
    """
    Generates realistic sensor data for development and demo purposes.
    """
    
    def __init__(self, zone_id: int):
        self.zone_id = zone_id
        self.state: Dict[str, float] = {}  # Persistent state for continuity
        self.last_irrigation: Optional[datetime] = None
        self.last_ph_dose: Optional[datetime] = None
        self.last_nutrient_dose: Optional[datetime] = None
        self.lights_on: bool = True
        
    def get_reading(self, sensor_type: str, reading_type: str, 
                    timestamp: Optional[datetime] = None) -> float:
        """
        Generate a realistic sensor reading.
        """
        timestamp = timestamp or datetime.now()
        profile = SENSOR_PROFILES.get(sensor_type, {}).get(reading_type, {})
        
        if not profile:
            # Handle inherited profiles (like bme680 inheriting from bme280)
            if sensor_type == 'bme680' and reading_type in ['temperature', 'humidity', 'pressure']:
                profile = SENSOR_PROFILES['bme280'].get(reading_type, {})
            
            if not profile:
                return 0.0
        
        # Get or initialize state
        state_key = f"{sensor_type}_{reading_type}"
        if state_key not in self.state:
            self.state[state_key] = profile.get('base', 0.0)
        
        base_value = self.state[state_key]
        
        # Apply diurnal variation
        if 'diurnal_amplitude' in profile:
            hour = timestamp.hour + timestamp.minute / 60.0
            phase = profile.get('diurnal_phase', 12)
            amplitude = profile['diurnal_amplitude']
            diurnal = amplitude * math.sin((hour - phase) * math.pi / 12)
            base_value += diurnal
        
        # Apply drift
        if 'drift_per_hour' in profile:
            # Drift accumulates in state
            drift = profile['drift_per_hour'] * (random.random() * 0.5 + 0.75)
            self.state[state_key] += drift / 60  # Per-minute update
        
        # Apply decay (soil moisture, water level)
        if 'decay_per_hour' in profile:
            decay = profile['decay_per_hour'] / 60
            self.state[state_key] = max(
                profile.get('min', 0),
                self.state[state_key] - decay
            )
        
        # Apply consumption (water level, EC)
        if 'consumption_per_hour' in profile:
            consumption = profile['consumption_per_hour'] / 60
            self.state[state_key] = max(
                profile.get('min', 0),
                self.state[state_key] - consumption
            )
        
        # Light-dependent values
        if 'lights_on_value' in profile:
            if self.lights_on:
                base_value = profile['lights_on_value']
            else:
                base_value = profile.get('lights_off_value', 0)
        
        # Add noise
        noise = profile.get('noise', 0)
        if noise > 0:
            base_value += random.gauss(0, noise)
        
        # Inject occasional anomaly
        if random.random() < Config.SIM_ANOMALY_PROBABILITY:
            anomaly_factor = random.choice([0.7, 0.8, 1.2, 1.3])
            base_value *= anomaly_factor
        
        # Clamp to valid range
        min_val = profile.get('min', float('-inf'))
        max_val = profile.get('max', float('inf'))
        base_value = max(min_val, min(max_val, base_value))
        
        return round(base_value, 2)
    
    def trigger_irrigation(self):
        """Simulate irrigation event - boosts soil moisture."""
        self.last_irrigation = datetime.now()
        if 'soil_moisture_moisture' in self.state:
            boost = SENSOR_PROFILES['soil_moisture']['moisture']['irrigation_boost']
            self.state['soil_moisture_moisture'] = min(100, 
                self.state['soil_moisture_moisture'] + boost)
    
    def trigger_ph_dose(self, direction: str = 'down'):
        """Simulate pH adjustment dose."""
        self.last_ph_dose = datetime.now()
        if 'ph_sensor_ph' in self.state:
            effect = SENSOR_PROFILES['ph_sensor']['ph']['dose_effect']
            if direction == 'up':
                effect = abs(effect)
            self.state['ph_sensor_ph'] += effect
    
    def trigger_nutrient_dose(self):
        """Simulate nutrient addition."""
        self.last_nutrient_dose = datetime.now()
        if 'ec_sensor_ec' in self.state:
            effect = SENSOR_PROFILES['ec_sensor']['ec']['dose_effect']
            self.state['ec_sensor_ec'] += effect
    
    def set_lights(self, on: bool):
        """Update light state for light-dependent sensors."""
        self.lights_on = on
    
    def generate_historical_data(self, sensor_type: str, reading_type: str,
                                  start: datetime, end: datetime,
                                  interval_minutes: int = 5) -> List[SimulatedReading]:
        """
        Generate historical data for backfilling.
        Useful for demos and testing analytics.
        """
        readings = []
        current = start
        
        # Reset state to simulate from scratch
        temp_state = self.state.copy()
        self.state = {}
        
        while current <= end:
            value = self.get_reading(sensor_type, reading_type, current)
            readings.append(SimulatedReading(
                sensor_id=0,  # Set by caller
                reading_type=reading_type,
                value=value,
                timestamp=current
            ))
            current += timedelta(minutes=interval_minutes)
        
        self.state = temp_state
        return readings
