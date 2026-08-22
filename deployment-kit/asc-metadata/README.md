# App Store Connect — 메타데이터 업로드 (Time Capital)

문구 파일을 수정한 뒤 스크립트로 App Store Connect에 반영합니다.

- **Bundle ID:** `com.smartcompany.longterminvestment`
- **한국어 앱명:** 타임 캐피탈
- **영문 앱명:** Time Capital

## 파일

### `listings.mjs`
로케일별 스토어 문구 (ko, en-US, ja, zh-Hans).

### `store-urls.mjs`
공통 `privacyUrl`, `supportUrl`, `marketingUrl`, `copyright`.

### `whats-new.json`
버전별 새로운 기능.

### `review-notes.mjs`
심사팀용 App Review Notes.

## 1회 설정

```bash
cd client/deployment-kit/asc-metadata
cp .env.example .env
```

`.env`에 `ASC_ISSUER_ID`를 채우세요 (App Store Connect → Users and Access → Keys).

## 사용

`client/` 에서:

```bash
./deployment-kit/scripts/upload_ios_metadata.sh --dry-run
./deployment-kit/scripts/upload_ios_metadata.sh
./deployment-kit/scripts/upload_ios_metadata.sh --only promotionalText
./deployment-kit/scripts/upload_ios_metadata.sh --only reviewNotes
./deployment-kit/scripts/upload_ios_metadata.sh --only whatsNew
```

또는 이 폴더에서:

```bash
cd client/deployment-kit/asc-metadata
./update-metadata.sh --dry-run
./update-whats-new.sh
```
