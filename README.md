# 🐔 HCKEgg Aviculture 360º — Lite Version

**Intelligent Poultry Management, Offline-First and Zero-Cost**

A Flutter mobile application for small and medium-sized poultry producers raising laying hens. Control production, costs, and herd health — all working offline, syncing to the cloud when connected.

---

## 🎯 About the Project

HCKEgg is an innovative solution that modernizes rural poultry management, bringing accessible technology to farmers in the field. Built with **Flutter**, **SQLite (Drift)** local database, and free **Supabase** backend, it offers professional features with zero infrastructure costs.

**Current Version**: Lite (0€/month)  
**Target Audience**: Small and medium-sized poultry producers (50-500 hens)  
**Platforms**: Android (iOS on roadmap)

---

## ✨ Key Features

### 📊 Herd Management
- Detailed registry of each hen (ID, breed, date of birth)
- Grouping by batches with history
- Mortality control and replacement tracking

### 🥚 Production Control
- Daily egg production logging
- Classification by size and quality
- Real-time performance dashboards

### 💰 Cost Management
- Feed and cost tracking
- Medications and treatments registry
- Automatic profitability calculation per hen

### 📅 Health & Wellness
- Vaccination calendar
- Common disease alerts
- Treatment history

### 📱 Offline-First Experience
- Works 100% without internet connection
- Automatic sync when reconnecting
- Data always available locally

---

## 🏗️ Technical Architecture

```
┌─────────────────────────────────────────┐
│  Flutter App (Offline-First)            │
│  ├─ Drift/SQLite (Local Database)       │
│  ├─ Provider (State Management)         │
│  └─ Firebase Analytics + Crashlytics    │
└────────────┬────────────────────────────┘
             │ (Synchronization)
             ↓
┌─────────────────────────────────────────┐
│  Supabase (Free Backend)                │
│  ├─ PostgreSQL (Auth + Data)            │
│  ├─ Row Level Security (RLS)            │
│  └─ Edge Functions (when scaled)        │
└─────────────────────────────────────────┘
```

### Technology Stack

| Component       | Technology     | Version |
|-----------------|----------------|---------|
| **Frontend**    | Flutter        | 3.38.1  |
| **Language**    | Dart           | 3.10.0  |
| **Local DB**    | SQLite (Drift) | 2.29.0  |
| **State Mgmt**  | Provider       | 6.1.5   |
| **Backend**     | Supabase       | 2.10.3  |
| **Analytics**   | Firebase       | 12.0.4  |
| **HTTP Client** | Dio            | 5.3.2   |
|-----------------|----------------|---------|
---

## 🚀 Quick Start

### Prerequisites

- Flutter 3.38.1+
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

# 3. Generate code (Drift + JSON)
dart run build_runner build

# 4. Run the app
flutter run
```

### Running in Development Mode

```bash
# Hot reload enabled
flutter run

# Verbose mode (debug)
flutter run -v

# Specific device
flutter run -d <device-id>
```

---

## 📁 Project Structure

```
hckegg_lite/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── domain/
│   │   ├── entities/             # Business models
│   │   │   ├── hen.dart
│   │   │   ├── batch.dart
│   │   │   └── daily_production.dart
│   │   └── repositories/         # Repository interfaces
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart # Drift database
│   │   │   ├── tables/           # Table definitions
│   │   │   └── daos/             # Data Access Objects
│   │   ├── datasources/          # Local & Remote sources
│   │   └── repositories/         # Repository implementations
│   ├── presentation/
│   │   ├── pages/                # App screens
│   │   ├── widgets/              # Reusable widgets
│   │   ├── providers/            # Riverpod providers
│   │   └── theme/                # Styles and themes
│   └── utils/
│       ├── constants.dart        # Global constants
│       └── helpers.dart          # Helper functions
├── test/                         # Unit and integration tests
├── pubspec.yaml                  # Project dependencies
└── README.md                      # This file
```

---

## 🗄️ Database

### Main Tables

**Hens**
- ID, Identification, Breed, Date of Birth, Status, Batch

**Batches**
- ID, Name, Start Date, End Date, Initial Quantity

**Daily Production**
- ID, Date, Hen ID, Eggs, Quality, Batch

**Costs**
- ID, Date, Type (Feed/Medication), Amount, Description

**Treatments**
- ID, Date, Hen ID, Type, Description, Completion Date

---

## 🔐 Security

- ✅ **Authentication**: JWT with Supabase Auth
- ✅ **Authorization**: Row Level Security (RLS) on Postgres
- ✅ **Communication**: SSL/TLS
- ✅ **Local Data**: Encrypted SQLite
- ✅ **Privacy**: Zero personal data collection without consent

---

## 📊 Performance & Limits

| Metric          | Limit            | Status  |
|-----------------|------------------|---------|
| Hens per app    | Unlimited        | ✅       |
| History         | 30 days          | ✅       |
| Sync            | Manual/Automatic | ✅       |
| DB Size         | <500MB           | ✅       |
| Supabase Egress | 2GB/month        | ✅       |
|-----------------|------------------| --------|

---

## 📄 License

This project is licensed under the **MIT License**. See `LICENSE` for details.

---

## 📞 Support & Contact

- **Email**: [your-email@hckegg.com]
- **GitHub Issues**: [Report bugs and suggestions]
- **Website**: [hckegg.com] (in development)

---

## 🙏 Acknowledgments

- **Simon Binder** - Drift ORM
- **Supabase Team** - Open-source backend
- **Flutter Community** - Support and tools

---

**Built with ❤️ to modernize poultry farming.**

*HCKEgg © 2025 - Aviculture 360º*
