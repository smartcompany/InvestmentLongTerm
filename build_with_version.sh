#!/bin/bash

# pubspec.yaml 파일 경로
PUBSPEC_FILE="pubspec.yaml"

# 현재 버전 읽기
CURRENT_VERSION=$(grep "^version:" $PUBSPEC_FILE | sed 's/version: //')
VERSION_NAME=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# 빌드 번호 증가
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="$VERSION_NAME+$NEW_BUILD_NUMBER"

echo "Updating version from $CURRENT_VERSION to $NEW_VERSION"

# Flutter 명령어로 버전 업데이트 및 빌드
flutter build appbundle --release --build-number=$NEW_BUILD_NUMBER

# pubspec.yaml도 업데이트
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" $PUBSPEC_FILE
rm -f $PUBSPEC_FILE.bak

echo "Build completed with version $NEW_VERSION"
