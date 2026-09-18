# swifty_companion

A new Flutter project.

## Run

1. Regenerate the 42 client secret previously shared in the conversation. Do not commit the new secret.
2. Run `flutter pub add http` once to install the browser-compatible HTTP client.
3. Put `.env` in the project root, alongside `backend/`, with `42_CLIENT_ID=...` and `42_CLIENT_SECRET=...`. Run `dart backend/server.dart` from that root. The server reads `.env` automatically; do not use `source .env` because these variable names start with a digit. The default port is 8080 (`PORT` overrides it). Never commit `.env`.
4. Start Flutter with `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8080` for Chrome on the same computer as the backend. Use `flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080` for an Android emulator. For a real Android phone on the same Wi-Fi, replace `10.0.2.2` with the computer's LAN IP. Use HTTPS for a remotely hosted server.
5. For local HTTP debugging on Android, configure your app's AndroidManifest.xml `android:usesCleartextTraffic="true"` in the `<application>` tag, or use HTTPS. Do not enable cleartext traffic for a production deployment.

`flutter run -d R3CX10PCLMY --dart-define=API_BASE_URL=http://192.168.122.1:8080`
