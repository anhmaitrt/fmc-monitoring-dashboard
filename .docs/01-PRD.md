# Product Requirements Document (PRD)

**Project Name:** FMC Monitoring Dashboard

## 1. Overview
The FMC Monitoring Dashboard is a Flutter-based web application designed to monitor user data, specifically focusing on Continuous Glucose Monitoring (CGM) metrics. It allows administrators to view user details, analyze CGM data logs, and manage file-based data sources.

## 2. Core Features

### 2.1 User Management
- **List Users**: View a dashboard of users monitored by the system.
- **User Details**: Detailed view of a specific user's metrics and data.

### 2.2 Data Monitoring (CGM)
- **CGM Data Visualization**: Charts and tables to display glucose levels over time.
- **Interruption Tracking**: Monitor data gaps or interruptions in CGM readings (`InterruptionRange`).
- **Sync Status**: Track synchronization gaps (`SyncGap`).

### 2.3 Data Logs & Files
- **Log Management**: View system or data logs.
- **File Handling**: Upload or manage CSV/data files for processing.

### 2.4 Authentication
- **Login**: Secure access to the dashboard.
- **Google Sign-In**: Integration with Google authentication.

## 3. User Flow
1. **Login**: User authenticates via Google Sign-In.
2. **Dashboard (Home)**: User sees an overview of monitored subjects.
3. **Drill-down**: User clicks on a subject to view `User Details`.
4. **Analysis**: User reviews charts and logs for that subject.

## 4. Future Roadmap
- [ ] Advanced filtering for users.
- [ ] Exportable reports.
- [ ] Real-time alerts for critical CGM values.
