# Task: HVAC Renaming, Modbus Refinements, and Zone Fixes

## Status
- [x] **Add Modbus Constants**: Added `WAVESHARE_MODULE_BASE`, `MODBUS_WRITE_SINGLE_COIL`, etc. to `ModbusProtocol`.
- [x] **Fix Relay Indexing**: Updated `HardwareService` to use 0-7 indexing internally and removed redundant conversions.
- [x] **Configurable Serial Port**: Verified `ModbusService` uses database settings for serial ports.
- [x] **Stateful Modbus Mock**: Improved `ModbusService` mock to maintain relay state.
- [x] **Zone B Grow Method Fix**: 
    - Updated `DatabaseHelper.updateZone` to support `growMethod` and renamed `hasVentilation` to `hasHvac`.
    - Added auto-correction in `ZoneDashboardScreen` to update `growMethod` if irrigation is Reservoir.
    - Updated `GrowTypeSelectionScreen` to set `growMethod` correctly on setup.
    - [x] **Database Schema Fix**: Added `grow_method` column to `zones` table via migration (v23) and updated table creation logic.
    - [x] **UI Refresh Fix**: Updated `ZoneSetupScreen` to reload zones after returning from setup, ensuring the grow method text updates immediately.
- [x] **HVAC Renaming**:
    - Renamed "Ventilation" to "HVAC" in `ZoneConfigurationScreen` UI text.
    - Renamed `hasVentilation` to `hasHvac` in `ZoneConfigurationScreen` logic.
- [x] **Build Fixes**:
    - Fixed undefined `ventilationSettings` in `zone_dashboard_screen.dart`.
    - Fixed `TextButton` syntax in `hvac_screen.dart`.
- [x] **Release V1.3**:
    - Committed all changes.
    - Tagged as `v1.3`.
    - Pushed to remote.
- [x] **Grow Method Info**:
    - Implemented info dialog for grow method in `ZoneSetupScreen`.
- [x] **Generic Relay Names**:
    - Updated `_createDefaultIoChannels` to use generic names.
    - Added migration v24 to rename existing channels.
- [x] **Release V1.4**:
    - Committed changes.
    - Tagged as `v1.4`.
    - Pushed to remote.

## Next Steps
- **Deploy to RPi**:
    - [ ] Verify SSH connection (currently failing).
    - [ ] Transfer code.
    - [ ] Build and run on RPi.
