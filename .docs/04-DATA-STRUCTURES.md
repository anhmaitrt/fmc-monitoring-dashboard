# Data Structures

## 1. Core Models

### `UserModel`
Represents a monitored user in the system.
- Likely contains identifiers, names, and status fields.

### `UserCgmDataRow`
The primary data point for Continuous Glucose Monitoring.
- Timestamp
- Glucose Value
- Trend/Direction
- Source device info

## 2. metrics

### `InterruptionRange`
Tracks periods where data is missing or interrupted.
- `startTime`
- `endTime`
- `duration`

### `SyncGap`
Tracks gaps in synchronization between the device and the dashboard.

## 3. Logs

### `Log`
Generic log entry for system events or data processing steps.

## 4. Data Sources
- **CSV Files**: The system parses CSV files to populate these models.
- **JSON Assets**: `assets/users.json` serves as a static or initial data source.
