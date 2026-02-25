# Technical Specification

**Project:** FMC Monitoring Dashboard
**Framework:** Flutter (Web)

## 1. Architecture
The project follows a **Feature-First** architecture, organizing code by business features rather than technical layers.

### Structure
- `lib/feature/`: Contains feature-specific code (UI, Logic).
  - `home`, `login`, `user_details`, `log`, `file`.
- `lib/core/`: Shared utilities and components.
  - `components`: Reusable UI widgets.
  - `services`: Singleton services (API, Auth).
  - `utils`: Helper functions.
  - `routing`: Navigation logic.
- `lib/model/`: Data models.
- `lib/repo/`: Data access layer.

## 2. Technology Stack

### Core
- **Framework**: Flutter Web
- **Language**: Dart 3.x

### State Management
- **GetX (`get`)**: Used for reactive state management, dependency injection, and route management.

### Backend & Data
- **Google APIs**: `googleapis`, `googleapis_auth` for backend services.
- **File Format**: CSV parsing (`csv`) for data ingestion.
- **Local Storage**: `shared_preferences` for persisting local settings.

### UI & Visualization
- **Charts**: `fl_chart` for CGM data visualization.
- **Navigation**: `sidebarx` for the side menu.
- **Webview**: `flutter_inappwebview` (likely for specific content rendering).

### Code Generation
- `json_serializable` & `freezed`: For immutable data models and JSON parsing.

## 3. Key Dependencies
| Package | Purpose |
|---------|---------|
| `get` | State management & Routing |
| `fl_chart` | Data visualization |
| `googleapis` | Backend interaction |
| `envied` | Environment variable management |

## 4. Build & Deployment
- **CI/CD**: GitHub Actions (`.github/workflows/flutter-web.yml`).
- **Platform**: Web.
