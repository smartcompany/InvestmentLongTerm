# Deployment Kit — Time Capital

배포 직전마다 AI에게 여러 번 설명하지 않도록 만든 단일 폴더입니다.  
`app-config.json`이 이 앱의 bundle id, package name, URL, 키 경로를 담습니다.

## 구조

```
deployment-kit/
├── app-config.json          # Time Capital 앱 설정
├── app-config.example.json  # 새 앱용 템플릿
├── asc-metadata/            # App Store Connect 메타데이터
├── play-metadata/           # Google Play 메타데이터
└── scripts/
    ├── build_android.sh
    ├── build_ios.sh
    ├── upload_ios_metadata.sh
    ├── upload_android_metadata.sh
    ├── release_all.sh
    ├── release_ios_all.sh
    └── release_android_all.sh
```

## 메타데이터 갱신 (가장 자주 쓰는 명령)

`client/` 에서:

```bash
# App Store — 미리보기
./deployment-kit/scripts/upload_ios_metadata.sh --dry-run

# App Store — 실제 업로드
./deployment-kit/scripts/upload_ios_metadata.sh

# Google Play — 미리보기
./deployment-kit/scripts/upload_android_metadata.sh --dry-run

# Google Play — 실제 업로드
./deployment-kit/scripts/upload_android_metadata.sh

# What's New만
./deployment-kit/asc-metadata/update-whats-new.sh
./deployment-kit/play-metadata/update-whats-new.sh
```

## 1회 설정

### iOS (App Store Connect API)

```bash
cd client/deployment-kit/asc-metadata
cp .env.example .env
# ASC_ISSUER_ID=... 입력 (App Store Connect → Users and Access → Keys)
```

### Android (Play Console API)

```bash
cd client/deployment-kit/play-metadata
cp .env.example .env
npm install
# PLAY_SERVICE_ACCOUNT_JSON 경로 확인
```

## 문구 수정 위치

| 파일 | 내용 |
|------|------|
| `asc-metadata/listings.mjs` | 앱명, 부제, 설명, 키워드 (4개 언어) |
| `asc-metadata/whats-new.json` | 버전별 새로운 기능 |
| `asc-metadata/review-notes.mjs` | 심사팀용 메모 |
| `asc-metadata/store-urls.mjs` | privacy / support / marketing URL |
| `play-metadata/listings.mjs` | Play용 (asc listings 자동 변환) |

## 전체 릴리스

```bash
# iOS 전체 (메타 + 빌드)
./deployment-kit/scripts/release_ios_all.sh

# Android 전체 (빌드 + 메타)
./deployment-kit/scripts/release_android_all.sh

# 선택 실행
./deployment-kit/scripts/release_all.sh --ios-meta --android-meta --dry-run
```

## 앱 정보 (Time Capital)

- **Bundle ID:** `com.smartcompany.longterminvestment`
- **Package:** `com.smartcompany.longterminvestment`
- **Server:** `https://investment-long-term-server.vercel.app`
- **Privacy:** `https://investment-long-term-server.vercel.app/privacy`

자세한 API 설정은 `asc-metadata/README.md`, `play-metadata/README.md` 참고.
