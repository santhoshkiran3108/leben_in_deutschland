#!/bin/bash

echo "🧹 Cleaning..."
flutter clean

echo "🔨 Building macOS app (first pass)..."
flutter build macos || true

APP_PATH="build/macos/Build/Products/Release/leben_in_deutschland.app"

echo "🧼 Stripping macOS extended attributes..."
xattr -rc "$APP_PATH"

echo "🔏 Re-signing with ad-hoc signature..."
codesign --force --deep --sign - "$APP_PATH"

echo "🚀 Launching the app..."
open "$APP_PATH"