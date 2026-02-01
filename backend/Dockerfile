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
FROM dart:stable AS production

WORKDIR /app

# Copy built artifacts
COPY --from=build /app/build /app/build
COPY --from=build /app/pubspec.* /app/
COPY --from=build /app/docs /app/docs

# Install production dependencies only
RUN dart pub get --no-dev-dependencies

# Expose port
EXPOSE 8080

# Run the server
CMD ["dart", "build/bin/server.dart"]
