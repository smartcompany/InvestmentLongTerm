# Google Play — 메타데이터 업로드 (My Assets AI)

- **Package:** `com.smartcompany.longterminvestment`
- **앱명:** My Assets AI

**업로드 범위**
| 스크립트 | 내용 |
|---------|------|
| `upload_android_aab.sh` | **AAB** 업로드 → track에 draft(기본) 등록 |
| `upload_android_metadata.sh` | 앱 이름, 짧은/긴 설명, 연락처, **출시 노트** |
| `upload_android_screenshots.sh` | 앱 아이콘(512), **마케팅 이미지**(1024×500), 폰 스크린샷(언어별 5장) |
| `upload_android_whats_new.sh` | 출시 노트 (production draft 빌드) |

출시 노트 원본: `../asc-metadata/whats-new.json` (iOS와 공유)

```bash
cd client/deployment-kit/play-metadata
cp .env.example .env
npm install
../scripts/upload_android_metadata.sh --dry-run
../scripts/upload_android_whats_new.sh --version-code 32 --dry-run
```
