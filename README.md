🥚 HCKEgg Lite — Mobile Poultry Management App

HCKEgg Lite is a lightweight, offline-first mobile application designed for small and medium poultry farms.
It enables egg tracking, batch management, production history, and cloud synchronization — all while running at zero backend cost thanks to Supabase Free Tier.

This repository contains the complete Flutter implementation of the Lite version.

🚀 Features
✅ Core Functionalities

Offline-first database using Drift + SQLite

Local caching and sync queues

Manual or background sync with Supabase

Egg entry creation, editing, deletion

Production timeline & basic dashboard

User authentication (email/password + optional OAuth)

Secure cloud backup through Supabase Storage

📡 Backend (Zero-cost Architecture)

Supabase Free Tier

Auth

PostgreSQL (+ RLS security policies)

Storage

Logs

No paid servers, no microservices

🛡️ Stability & Monitoring

Firebase Crashlytics for error tracking

Firebase Analytics (optional)

Supabase logs for backend activity

🔒 Security

Row Level Security in Supabase

JWT handling

HTTPS-only data transfer

🏛️ System Architecture
Flutter App (Mobile)
│
├── Offline Layer
│     ├── Drift (SQLite)
│     ├── Local queue system
│     └── Local dashboards
│
├── Sync Layer
│     ├── Incremental sync
│     ├── Timestamp-based deltas
│     └── Batch upload
│
└── Supabase Backend
├── Auth
├── PostgreSQL
├── Storage
└── RLS Security

🛠️ Tech Stack
Component	Technology
UI Framework	Flutter (Dart)
Local DB	Drift (SQLite)
Backend	Supabase
Cloud Storage	Supabase Storage
Crash Reporting	Firebase Crashlytics
Analytics	Firebase Analytics
HTTP Client	Dio
State Management	Provider
📁 Project Structure
lib/
├── src/
│   ├── db/
│   │   ├── app_database.dart
│   │   └── tables/
│   ├── features/
│   ├── services/
│   ├── screens/
│   └── widgets/
└── main.dart

🧱 Installation & Setup
1. Clone the repo
   git clone https://github.com/<your-user>/hckegg_lite.git
   cd hckegg_lite

2. Install dependencies
   flutter pub get

3. Configure Supabase

Create a .env or a config file with:

const String supabaseUrl = "YOUR_SUPABASE_URL";
const String supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";


Enable:

Auth (email)

RLS policies

Tables according to your schema

4. Configure Firebase (Crashlytics & Analytics)
   flutterfire configure


Then:

Add google-services.json to android/app/

Ensure Gradle files are updated automatically

5. Generate Drift files
   flutter pub run build_runner build --delete-conflicting-outputs

▶️ Running the App
Android
flutter run

Build release
flutter build apk --release

🧩 Environment Requirements

Flutter SDK 3.10+

Dart 3.10+

Android Studio / VS Code

Supabase project

Firebase project (optional but recommended)

🧮 Local Database Example (Drift)
class Eggs extends Table {
IntColumn get id => integer().autoIncrement()();
TextColumn get tag => text()();
IntColumn get weight => integer().nullable()();
DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

📦 Offline-First Sync Logic (Summary)

Each local change is added to a sync queue.

When internet is available, the queue is processed.

Sync uses:

Timestamps for incremental updates

Batching for low bandwidth

Automatic conflict resolution

📜 Roadmap (Lite → Pro Upgrade Path)

Add advanced charts (production, mortality, feed)

Add multi-farm support

Automatic background sync

IoT sensor integration (Pro+ edition)

Web dashboard

AI insights (Enterprise edition)

🤝 Contributing

Contributions are welcome!
Please open an issue or a PR with improvements or bug fixes.

📄 License

This project is proprietary software.
All rights reserved © HCKEgg.