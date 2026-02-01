# HCKEgg API - Production Dockerfile
FROM dart:stable

WORKDIR /app

# Copy all source files
COPY . .

# Get dependencies
RUN dart pub get

# Install dart_frog_cli (match runtime version exactly)
RUN dart pub global activate dart_frog_cli 1.2.2

# Remove any existing build
RUN rm -rf build

# Build the production server
RUN dart pub global run dart_frog_cli:dart_frog build

# Expose port
EXPOSE 8080

# Set environment
ENV PORT=8080
ENV HOST=0.0.0.0

# Run the server
CMD ["dart", "build/bin/server.dart"]
