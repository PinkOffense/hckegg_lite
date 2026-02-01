# HCKEgg API - Production Dockerfile
# Multi-stage build for optimal image size

# Stage 1: Build
FROM dart:stable AS build

WORKDIR /app

# Install dart_frog_cli
RUN dart pub global activate dart_frog_cli

# Copy pubspec files first for better caching
COPY pubspec.* ./
RUN dart pub get

# Copy source code
COPY . .

# Build the production server
RUN dart pub global run dart_frog_cli:dart_frog build

# Stage 2: Production
FROM dart:stable-slim AS production

WORKDIR /app

# Copy built artifacts
COPY --from=build /app/build /app/build
COPY --from=build /app/pubspec.* /app/
COPY --from=build /app/docs /app/docs

# Install production dependencies only
RUN dart pub get --no-dev-dependencies

# Create non-root user for security
RUN useradd -r -u 1001 appuser
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the server
CMD ["dart", "build/bin/server.dart"]
