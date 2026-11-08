# 천 마리 학 - 종이학 접기

소원을 적은 유리통에 매일 받는 색종이로 종이학을 접어 천 마리를 모으는 앱.

- 사이트: https://thousand-paper-cranes.ohsangplay.com (`index.html`, `privacy.html`, `terms.html`)
- 패키지명·번들 ID: `com.ohsang.util.thousandcranes`
- 웹 프로토타입: `design/prototype.html`

## Android (`android/`)

접기·유리통 화면은 `android/app/src/main/assets/www/index.html`이고 WebView로 띄운다. 네이티브는 보상형 광고(AdMob), 진동, 뒤로 가기, 시스템 바 여백만 맡는다. 기록은 WebView localStorage에 저장되고 기기 백업에 포함된다.

- 디버그 빌드에만 화면 아래 "테스트 도구"(다음 날로, 학 +50 등)가 보인다.
- 빌드: Actions → **Android 빌드**. main에 `android/**`를 push해도 자동으로 돈다.
- 최신 디버그 APK: https://github.com/thousand-paper-cranes/thousand-paper-cranes.github.io/releases/download/debug-latest/thousand-cranes-debug.apk

### Secrets

| Name | 값 |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | 업로드 키(jks) base64 |
| `ANDROID_KEYSTORE_PASSWORD` | 키스토어 비밀번호 |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ADMOB_APP_ID` | AdMob 앱 ID (`ca-app-pub-…~…`). 없으면 테스트 광고 |
| `ADMOB_REWARDED_ID` | 보상형 광고 단위 ID (`ca-app-pub-…/…`). 없으면 테스트 광고 |
| `PLAY_SERVICE_ACCOUNT_JSON` | (선택) Play 자동 업로드 |

글꼴(고운바탕, 고운돋움, 나눔손글씨 펜)은 SIL Open Font License이며 상용 한글 2,350자로 줄여 넣었다 (`assets/www/fonts/OFL.txt`).
