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

```bash
# Build
docker build -t hckegg-api .

# Run
docker run -p 8080:8080 \
  -e SUPABASE_URL=your-url \
  -e SUPABASE_SERVICE_ROLE_KEY=your-key \
  hckegg-api
```

## Deployment

### Railway (Recommended)

The backend is configured for automatic deployment to Railway:

1. **Create Railway Account**: https://railway.app
2. **Create New Project**: Connect your GitHub repository
3. **Configure Service**:
   - Root Directory: `backend`
   - Build: Dockerfile
4. **Add Environment Variables**:
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `PORT` (Railway sets this automatically)
5. **Get Railway Token**:
   - Go to Account Settings → Tokens
   - Create new token
   - Add as `RAILWAY_TOKEN` secret in GitHub repository

### GitHub Actions

Deployment is automated via GitHub Actions:
- Push to `master` branch triggers deployment
- Only deploys when files in `backend/` are changed
- Workflow: `.github/workflows/deploy-backend.yml`

### Required Secrets (GitHub Repository)

| Secret | Description |
|--------|-------------|
| `RAILWAY_TOKEN` | Railway API token for deployment |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key |

### Required Variables (GitHub Repository)

| Variable | Description |
|----------|-------------|
| `BACKEND_URL` | Deployed backend URL (e.g., https://hckegg-api.up.railway.app) |

## API Documentation

- **Local**: http://localhost:8080/docs
- **Production**: https://your-railway-url/docs
- **GitHub Pages**: https://pinkoffense.github.io/hckegg_lite/api-docs/

## License

MIT
