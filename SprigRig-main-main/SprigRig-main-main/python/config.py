import os

class Config:
    # Hardware mode: 'real', 'simulate', 'replay'
    HARDWARE_MODE = os.getenv('SPRIGRIG_HARDWARE_MODE', 'simulate')
    
    # Simulation settings
    SIM_UPDATE_INTERVAL_SECONDS = 60  # How often to generate new readings
    SIM_ANOMALY_PROBABILITY = 0.02    # 2% chance of anomaly injection
    SIM_NOISE_FACTOR = 0.05           # 5% random noise on readings
    
    # Data logging
    SENSOR_LOG_INTERVAL_SECONDS = 300  # Log to DB every 5 minutes
    DATA_RETENTION_DAYS = 90           # Keep raw data for 90 days
    
    # Database
    DB_PATH = os.getenv('SPRIGRIG_DB_PATH', 'sprigrig.db')
