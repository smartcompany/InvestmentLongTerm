#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Broken sdkman JAVA_HOME breaks plugin Kotlin→Java compile.
if [[ -z "${JAVA_HOME:-}" || ! -x "${JAVA_HOME}/bin/java" ]]; then
  if [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" ]]; then
    export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  elif [[ -x "/opt/homebrew/opt/openjdk@17/bin/java" ]]; then
    export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  fi
fi

cd "$CLIENT_DIR"

PUBSPEC_FILE="pubspec.yaml"
KEY_PROPERTIES="android/key.properties"

if [[ ! -f "$KEY_PROPERTIES" ]]; then
  echo "ERROR: $KEY_PROPERTIES not found. Create your Android release keystore config first."
  exit 1
fi

CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //')
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)
if [[ "$CURRENT_VERSION" != *"+"* ]]; then
  BUILD_NUMBER=1
fi

NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD_NUMBER"

echo "Updating version from $CURRENT_VERSION to $NEW_VERSION"
echo "Using JAVA_HOME=${JAVA_HOME:-"(unset)"}"

flutter pub get
flutter build appbundle --release --build-number="$NEW_BUILD_NUMBER"

if sed --version >/dev/null 2>&1; then
  sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
else
  sed -i '' "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"
fi

echo "Build completed with version $NEW_VERSION"
