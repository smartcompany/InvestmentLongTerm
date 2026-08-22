# Google Play — 메타데이터 업로드 (Time Capital)

App Store 문구(`../asc-metadata/listings.mjs`)를 Play 형식으로 변환해 업로드합니다.

- **Package:** `com.smartcompany.longterminvestment`

## 1회 설정

```bash
cd client/deployment-kit/play-metadata
cp .env.example .env
npm install
```

## 사용

`client/` 에서:

```bash
./deployment-kit/scripts/upload_android_metadata.sh --dry-run
./deployment-kit/scripts/upload_android_metadata.sh
./deployment-kit/play-metadata/update-whats-new.sh
```

Privacy policy URL은 Play API로 설정할 수 없습니다.  
콘솔 → Policy → App content → Privacy policy에  
`https://investment-long-term-server.vercel.app/privacy` 를 한 번 등록하세요.
