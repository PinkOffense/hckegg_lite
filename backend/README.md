# HCKEgg API Backend

Backend API for HCKEgg egg production management, built with **Dart Frog** and **Clean Architecture**.

## Architecture

```
backend/
├── lib/
│   ├── core/                    # Core utilities
│   │   ├── errors/              # Failures and Result type
│   │   ├── usecases/            # Base UseCase interface
│   │   └── utils/               # Supabase client, helpers
│   │
│   └── features/                # Feature modules
│       ├── eggs/
│       │   ├── domain/          # Business logic
│       │   │   ├── entities/    # Egg record entity
│       │   │   ├── repositories/# Repository interface
│       │   │   └── usecases/    # Use cases
│       │   └── data/
│       │       └── repositories/# Supabase implementation
│       ├── sales/
│       ├── expenses/
│       └── ...
│
├── routes/                      # API Routes (Dart Frog)
│   ├── _middleware.dart         # Global middleware
│   ├── index.dart               # Root endpoint
│   ├── health.dart              # Health check
│   └── api/
│       ├── _middleware.dart     # Auth middleware
│       └── v1/
│           ├── eggs/
│           │   ├── index.dart   # GET/POST /eggs
│           │   ├── [id].dart    # GET/PUT/DELETE /eggs/:id
│           │   └── statistics.dart
│           └── ...
│
└── test/                        # Tests
```

## Getting Started

### Prerequisites

- Dart SDK >= 3.0.0
- Dart Frog CLI: `dart pub global activate dart_frog_cli`

### Installation

```bash
cd backend
dart pub get
```

### Configuration

Copy `.env.example` to `.env` and fill in your Supabase credentials:

```bash
cp .env.example .env
```

### Running the Server

```bash
# Development (with hot reload)
dart_frog dev

# Production
dart_frog build
dart build/bin/server.dart
```

## API Endpoints

### Authentication

All `/api/*` endpoints require authentication via Bearer token:

```
Authorization: Bearer <supabase-jwt-token>
```

### Eggs

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/eggs` | Get all egg records |
| GET | `/api/v1/eggs?start_date=X&end_date=Y` | Get records in range |
| GET | `/api/v1/eggs/:id` | Get record by ID |
| POST | `/api/v1/eggs` | Create new record |
| PUT | `/api/v1/eggs/:id` | Update record |
| DELETE | `/api/v1/eggs/:id` | Delete record |
| GET | `/api/v1/eggs/statistics?start_date=X&end_date=Y` | Get statistics |

### Example Request

```bash
# Create egg record
curl -X POST http://localhost:8080/api/v1/eggs \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "date": "2024-01-15",
    "eggs_collected": 24,
    "eggs_broken": 2,
    "eggs_consumed": 4,
    "notes": "Good day"
  }'
```

## Clean Architecture

The backend follows Clean Architecture principles:

1. **Domain Layer** (innermost)
   - Entities: Pure business objects
   - Repositories: Abstract interfaces
   - Use Cases: Business logic

2. **Data Layer**
   - Repository Implementations: Supabase integration
   - Data Sources: External services

3. **Presentation Layer** (routes)
   - HTTP handlers
   - Request/Response mapping

## Testing

```bash
dart test
```

## Docker

```dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart pub get
RUN dart_frog build

FROM dart:stable
COPY --from=build /app/build /app
WORKDIR /app
CMD ["dart", "bin/server.dart"]
```

## License

MIT
