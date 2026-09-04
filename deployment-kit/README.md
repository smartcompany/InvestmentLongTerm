# Deployment Kit — My Assets AI

배포 직전에 AI에게 여러 번 설명하지 않도록 만든 단일 폴더입니다.  
구조는 UseByDate `deployment-kit`과 동일하며, `app-config.json`이 이 앱의 bundle id · package · URL · 키 경로를 담습니다.

## 구조

```
deployment-kit/
├── app-config.json          # My Assets AI 앱 설정
├── app-config.example.json  # 새 앱용 템플릿
├── asc-metadata/            # App Store Connect 메타데이터
├── play-metadata/           # Google Play 메타데이터
└── scripts/
    ├── build_android.sh
    ├── build_ios.sh
    ├── upload_ios_metadata.sh
    ├── upload_android_metadata.sh
    ├── upload_android_aab.sh
    ├── upload_android_screenshots.sh
    ├── release_all.sh
    ├── release_ios_all.sh
    └── release_android_all.sh
```

## 사용법

`client/` 에서:

```bash
./deployment-kit/scripts/release_ios_all.sh
./deployment-kit/scripts/release_android_all.sh
./deployment-kit/scripts/upload_ios_metadata.sh --dry-run
./deployment-kit/scripts/upload_android_metadata.sh --dry-run
```

## 앱 정보

- **표시명 (전 언어 통일):** My Assets AI
- **Bundle ID:** `com.smartcompany.longterminvestment`
- **Package:** `com.smartcompany.longterminvestment`
- **Server:** `https://investment-long-term-server.vercel.app`
- **Privacy:** `https://investment-long-term-server.vercel.app/privacy`
