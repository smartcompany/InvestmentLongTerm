#!/usr/bin/env bash
set -euo pipefail

BUMP=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_DIR="$CLIENT_DIR"

for arg in "$@"; do
  case "$arg" in
    -b|--bump) BUMP=true ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [options] [project_dir]

Options:
  -b, --bump    pubspec build number 증가
  -h, --help    도움말
EOF
      exit 0
      ;;
    *)
      PROJECT_DIR="$arg"
      ;;
  esac
done

log()  { printf "\n\033[1;34m[ios-release]\033[0m %s\n" "$*"; }
fail() { printf "\n\033[1;31m[error]\033[0m %s\n" "$*" >&2; exit 1; }

command -v flutter >/dev/null || fail "Flutter가 PATH에 없음"

cd "$PROJECT_DIR" || fail "프로젝트 경로 진입 실패: $PROJECT_DIR"
[ -f pubspec.yaml ] || fail "pubspec.yaml 없음"
[ -d ios ] || fail "ios 폴더 없음"

CURRENT_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
[ -n "$CURRENT_VERSION" ] || fail "pubspec.yaml에서 version을 찾지 못함"

VERSION_NAME="${CURRENT_VERSION%%+*}"
BUILD_NUMBER="${CURRENT_VERSION#*+}"
if [[ "$CURRENT_VERSION" != *"+"* ]]; then
  BUILD_NUMBER="1"
fi

if $BUMP; then
  NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
  NEW_VERSION="${VERSION_NAME}+${NEW_BUILD_NUMBER}"
  log "빌드 번호 증가: $CURRENT_VERSION → $NEW_VERSION"
  if sed --version >/dev/null 2>&1; then
    sed -i "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml
  else
    sed -i '' "s/^version: .*/version: ${NEW_VERSION}/" pubspec.yaml
  fi
else
  NEW_BUILD_NUMBER="$BUILD_NUMBER"
  log "빌드 번호 증가는 건너뜀"
fi

log "flutter pub get"
flutter pub get

if [[ -d ios/fastlane && -f ios/fastlane/Fastfile ]]; then
  command -v fastlane >/dev/null || fail "fastlane이 필요합니다"
  log "flutter build ios --config-only --release"
  flutter build ios --config-only --release --build-number="$NEW_BUILD_NUMBER"
  log "fastlane release"
  (cd ios && fastlane release)
else
  log "fastlane 설정이 없어 flutter build ipa 사용"
  flutter build ipa --release --build-number="$NEW_BUILD_NUMBER"
fi

log "완료"
