import asyncio
import logging
import json
import os
from datetime import datetime
from typing import List, Optional, Dict, Any
import aiosqlite
from pydantic import BaseModel
from anthropic import Anthropic, HUMAN_PROMPT, AI_PROMPT

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class GuardianConfig(BaseModel):
    zone_id: int
    enabled: bool = False
    api_key: Optional[str] = None
    check_interval_hours: int = 24
    vision_enabled: bool = True
    data_analysis_enabled: bool = True
    alert_sensitivity: str = "medium" # low, medium, high

class GuardianReport(BaseModel):
    id: Optional[int] = None
    zone_id: int
    report_type: str # 'daily', 'alert', 'advice'
    content: str
    image_path: Optional[str] = None
    created_at: int

class GuardianService:
    def __init__(self, db_path: str = "sprig_rig.db"):
        self.db_path = db_path
        self._running = False

    async def get_config(self, zone_id: int) -> Optional[GuardianConfig]:
        async with aiosqlite.connect(self.db_path) as db:
            db.row_factory = aiosqlite.Row
            async with db.execute("SELECT * FROM guardian_config WHERE zone_id = ?", (zone_id,)) as cursor:
                row = await cursor.fetchone()
                if row:
                    return GuardianConfig(
                        zone_id=row['zone_id'],
                        enabled=bool(row['enabled']),
                        api_key=row['api_key'],
                        check_interval_hours=row['check_interval_hours'],
                        vision_enabled=bool(row['vision_enabled']),
                        data_analysis_enabled=bool(row['data_analysis_enabled']),
                        alert_sensitivity=row['alert_sensitivity']
                    )
        return None

    async def update_config(self, config: GuardianConfig):
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute("""
                INSERT INTO guardian_config (zone_id, enabled, api_key, check_interval_hours, vision_enabled, data_analysis_enabled, alert_sensitivity, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(zone_id) DO UPDATE SET
                    enabled=excluded.enabled,
                    api_key=excluded.api_key,
                    check_interval_hours=excluded.check_interval_hours,
                    vision_enabled=excluded.vision_enabled,
                    data_analysis_enabled=excluded.data_analysis_enabled,
                    alert_sensitivity=excluded.alert_sensitivity,
                    updated_at=excluded.updated_at
            """, (
                config.zone_id, int(config.enabled), config.api_key, config.check_interval_hours,
                int(config.vision_enabled), int(config.data_analysis_enabled), config.alert_sensitivity,
                int(datetime.now().timestamp())
            ))
            await db.commit()

    async def test_connection(self, api_key: str) -> bool:
        """Test if the API key is valid by making a minimal call."""
        try:
            client = Anthropic(api_key=api_key)
            message = client.messages.create(
                model="claude-3-haiku-20240307",
                max_tokens=10,
                messages=[
                    {"role": "user", "content": "Hello"}
                ]
            )
            return True
        except Exception as e:
            logger.error(f"API Connection Test Failed: {e}")
            return False

    async def generate_advice(self, zone_id: int) -> GuardianReport:
        logger.info(f"Generating advice for zone {zone_id}")
        
        config = await self.get_config(zone_id)
        if not config or not config.api_key:
            logger.warning(f"No API key found for zone {zone_id}")
            report = GuardianReport(
                zone_id=zone_id,
                report_type="error",
                content="Guardian AI is enabled but no API key is configured. Please add your Anthropic API key in settings.",
                created_at=int(datetime.now().timestamp())
            )
            await self._save_report(report)
            return report

        try:
            # TODO: Gather real context (sensor data, recent logs, camera image)
            # For now, we mock the context but use the REAL API to generate the advice
            context_prompt = """
            You are Guardian, an AI assistant for an automated hydroponic grow system called SprigRig.
            Current System Status:
            - pH: 6.2 (Target: 5.8-6.2) - Stable
            - EC: 1.8 mS/cm (Target: 1.5-2.0) - Optimal
            - Water Temp: 20C - Optimal
            - Air Temp: 24C - Optimal
            - Humidity: 55% - Optimal
            - Plant Stage: Vegetative (Week 3)
            
            Please provide a brief, encouraging status update and one actionable tip for the grower.
            """

            client = Anthropic(api_key=config.api_key)
            message = client.messages.create(
                model="claude-3-sonnet-20240229",
                max_tokens=300,
                messages=[
                    {"role": "user", "content": context_prompt}
                ]
            )
            
            advice_content = message.content[0].text

            report = GuardianReport(
                zone_id=zone_id,
                report_type="advice",
                content=advice_content,
                created_at=int(datetime.now().timestamp())
            )
            
            await self._save_report(report)
            return report

        except Exception as e:
            logger.error(f"Error generating advice: {e}")
            report = GuardianReport(
                zone_id=zone_id,
                report_type="error",
                content=f"Failed to generate advice: {str(e)}",
                created_at=int(datetime.now().timestamp())
            )
            await self._save_report(report)
            return report

    async def _save_report(self, report: GuardianReport):
        async with aiosqlite.connect(self.db_path) as db:
            await db.execute("""
                INSERT INTO guardian_reports (zone_id, report_type, content, image_path, created_at)
                VALUES (?, ?, ?, ?, ?)
            """, (report.zone_id, report.report_type, report.content, report.image_path, report.created_at))
            await db.commit()

    async def start_monitoring(self):
        self._running = True
        logger.info("Guardian Service started")
        while self._running:
            # Check schedules and run analysis if needed
            await asyncio.sleep(60) # Check every minute

    def stop(self):
        self._running = False
