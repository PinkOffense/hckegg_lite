# HCKEgg API - Production Dockerfile
# Single stage build for Dart Frog

FROM dart:stable

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

# Expose port
EXPOSE 8080

# Run the server
CMD ["dart", "build/bin/server.dart"]
