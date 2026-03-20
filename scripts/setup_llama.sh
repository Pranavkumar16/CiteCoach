#!/bin/bash
# ============================================================
# CiteCoach - llama.cpp Setup Script
# ============================================================
# Run this ONCE before building the app to download and
# configure llama.cpp for native on-device AI inference.
#
# Usage:
#   chmod +x scripts/setup_llama.sh
#   ./scripts/setup_llama.sh
# ============================================================

set -e

echo "=================================================="
echo "  CiteCoach - llama.cpp Native Setup"
echo "=================================================="
echo ""

# Android setup
ANDROID_CPP_DIR="android/app/src/main/cpp"

if [ -d "$ANDROID_CPP_DIR/llama.cpp" ]; then
    echo "[Android] llama.cpp already exists, updating..."
    cd "$ANDROID_CPP_DIR/llama.cpp"
    git pull
    cd -
else
    echo "[Android] Cloning llama.cpp..."
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git "$ANDROID_CPP_DIR/llama.cpp"
fi

echo ""
echo "[Android] llama.cpp ready!"
echo ""

# iOS setup
IOS_DIR="ios"

if [ -d "$IOS_DIR/llama.cpp" ]; then
    echo "[iOS] llama.cpp already exists, updating..."
    cd "$IOS_DIR/llama.cpp"
    git pull
    cd -
else
    echo "[iOS] Cloning llama.cpp..."
    git clone --depth 1 https://github.com/ggerganov/llama.cpp.git "$IOS_DIR/llama.cpp"
fi

echo ""
echo "[iOS] llama.cpp ready!"
echo ""

echo "=================================================="
echo "  Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Open the project in Android Studio or Xcode"
echo "  2. Build and run: flutter run"
echo ""
echo "The native CMake build (Android) and Xcode build (iOS)"
echo "will automatically compile llama.cpp during the first build."
echo "This may take 5-10 minutes on first build."
echo ""
