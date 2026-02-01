#!/bin/bash

# Coverage Report Generator for HCKEgg Lite
# Run: ./scripts/coverage.sh

set -e

echo "Running tests with coverage..."
flutter test --coverage

echo ""
echo "Generating coverage report..."

# Check if lcov is installed
if command -v lcov &> /dev/null; then
    # Remove generated files from coverage
    lcov --remove coverage/lcov.info \
        'lib/**/*.g.dart' \
        'lib/**/*.freezed.dart' \
        'lib/**/generated/**' \
        -o coverage/lcov_cleaned.info 2>/dev/null || true

    # Generate HTML report
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo ""
        echo "HTML coverage report generated at: coverage/html/index.html"
    fi

    # Show summary
    lcov --summary coverage/lcov.info
else
    echo "lcov not installed. Install with: brew install lcov (macOS) or apt install lcov (Linux)"
    echo ""
    echo "Coverage file generated at: coverage/lcov.info"
fi

echo ""
echo "Coverage complete!"
