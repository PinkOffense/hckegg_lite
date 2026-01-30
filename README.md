# HCKEgg Aviculture 360 - Lite Version

**Intelligent Poultry Management, Offline-First and Zero-Cost**

A Flutter mobile application for small and medium-sized poultry producers raising laying hens. Control production, costs, and herd health - all working offline, syncing to the cloud when connected.

---

## About the Project

HCKEgg is an innovative solution that modernizes rural poultry management, bringing accessible technology to farmers in the field. Built with **Flutter**, **Supabase** backend with offline support, it offers professional features with zero infrastructure costs.

**Current Version**: Lite (Free)
**Target Audience**: Small and medium-sized poultry producers (50-500 hens)
**Platforms**: Android, iOS, Web

---

## Key Features

### Production Control
- Daily egg production logging with date picker
- Classification tracking and notes
- Real-time performance dashboards with charts
- Search and filter records

### Sales Management
- Record egg sales with customer details
- Payment status tracking (Paid, Pending, Advance)
- Revenue analytics and reporting
- Payment history management

### Reservations
- Reserve eggs for customers
- Pickup date scheduling
- Convert reservations to sales
- Customer contact management

### Cost Management
- Feed stock tracking with OCR support for feed bags
- Expense categorization (Feed, Maintenance, Equipment, Utilities)
- Veterinary cost integration
- Profitability calculations

### Health & Wellness
- Veterinary records (vaccines, treatments, checkups)
- Severity levels (Low, Medium, High, Critical)
- **Appointment reminders** - Red badge on calendar icon when vet visits are scheduled
- Treatment history and notes

### Feed Stock with OCR
- Scan feed bags to extract brand, weight, and price
- Manual text correction for OCR results
- Stock level monitoring with alerts
- Usage tracking

### User Experience
- **Bilingual support**: Portuguese and English
- **Dark/Light theme** toggle
- **Offline-first** architecture
- Responsive design (Mobile, Tablet, Desktop)

---

## Technical Architecture

```
+------------------------------------------+
|  Flutter App (Offline-First)             |
|  +- Provider (State Management)          |
|  +- Supabase Client (Auth + Data)        |
|  +- Google ML Kit (OCR)                  |
+------------------+-----------------------+
                   | (Synchronization)
                   v
+------------------------------------------+
|  Supabase (Free Backend)                 |
|  +- PostgreSQL (Auth + Data)             |
|  +- Row Level Security (RLS)             |
|  +- Real-time subscriptions              |
+------------------------------------------+
```

### Technology Stack

| Component       | Technology      | Purpose                    |
|-----------------|-----------------|----------------------------|
| **Frontend**    | Flutter 3.x     | Cross-platform UI          |
| **Language**    | Dart 3.x        | Application logic          |
| **State Mgmt**  | Provider        | Reactive state management  |
| **Backend**     | Supabase        | Auth, Database, Storage    |
| **OCR**         | Google ML Kit   | Text recognition from images |
| **Charts**      | fl_chart        | Data visualization         |

---

## Quick Start

### Prerequisites

- Flutter 3.x+
- Android SDK 21+ or iOS 13+
- Git
- Editor: Android Studio or VS Code

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/hckegg-lite.git
cd hckegg_lite

# 2. Install dependencies
flutter pub get

# 3. Run the app
flutter run
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## Project Structure

```
hckegg_lite/
+-- lib/
|   +-- main.dart                 # App entry point
|   +-- app/                      # App configuration
|   |   +-- app_widget.dart       # Main app widget
|   |   +-- auth_gate.dart        # Authentication flow
|   +-- core/                     # Core utilities
|   |   +-- constants/            # App constants
|   |   +-- di/                   # Dependency injection
|   |   +-- models/               # Core models
|   +-- data/                     # Data layer
|   |   +-- datasources/remote/   # Remote data sources
|   |   +-- repositories/         # Repository implementations
|   +-- dialogs/                  # Dialog widgets
|   +-- domain/                   # Business logic
|   |   +-- repositories/         # Repository interfaces
|   +-- l10n/                     # Localization (PT/EN)
|   +-- models/                   # Data models
|   +-- pages/                    # App screens
|   +-- services/                 # Business services
|   +-- state/                    # State management
|   |   +-- providers/            # Provider classes
|   +-- widgets/                  # Reusable widgets
|       +-- charts/               # Chart widgets
+-- test/                         # Unit and widget tests
+-- pubspec.yaml                  # Dependencies
+-- README.md                     # This file
```

---

## Database Tables

| Table          | Description                              |
|----------------|------------------------------------------|
| egg_records    | Daily egg production records             |
| egg_sales      | Sales transactions                       |
| egg_reservations | Customer reservations                  |
| expenses       | Standalone expenses (feed, maintenance)  |
| vet_records    | Veterinary records and appointments      |
| feed_stock     | Feed inventory tracking                  |
| payments       | Payment transactions                     |
| profiles       | User profiles                            |

---

## Security

- **Authentication**: Email/Password with Supabase Auth
- **Authorization**: Row Level Security (RLS) on PostgreSQL
- **Communication**: SSL/TLS encryption
- **Privacy**: User data isolated by account

---

## Localization

The app supports two languages:
- **Portuguese (PT)** - Default
- **English (EN)**

Language can be changed from the app header menu.

---

## License

This project is licensed under the **MIT License**. See `LICENSE` for details.

---

## Support & Contact

- **GitHub Issues**: Report bugs and suggestions
- **Email**: support@hckegg.com

---

**Built with care to modernize poultry farming.**

*HCKEgg 2025 - Aviculture 360*
