#!/bin/bash

# Scribe Client PyPI Publishing Script
# Usage: ./publish.sh [version]

set -e

echo "🚀 Publishing scribe-client to PyPI..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf dist/ build/ *.egg-info/

# Build package
echo "📦 Building package..."
python -m build

# Check package
echo "✅ Verifying package..."
python -m twine check dist/*

# Upload to PyPI
echo "⬆️  Uploading to PyPI..."
python -m twine upload dist/*

echo "🎉 Successfully published to PyPI!"
echo "📦 View at: https://pypi.org/project/scribe-client/"
