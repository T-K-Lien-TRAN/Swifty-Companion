# Swifty Companion

A Flutter app for looking up 42 student profiles. A small Dart backend handles requests to the 42 API and keeps the client credentials and access tokens on the server.
Read Tutorial for Flutter here: https://docs.flutter.dev/learn

## Requirements

- Flutter and Dart installed and available on your PATH
- A 42 API client ID and client secret
- Chrome for web testing, or an Android device or emulator for mobile testing
- Android SDK and platform tools for Android testing (`adb`)

## Configure the backend

1. Create `.env` in the project root, alongside `backend/`:

```dotenv
42_CLIENT_ID=your_client_id
42_CLIENT_SECRET=your_client_secret
```

2. Keep `.env` out of version control. If a real client secret was previously committed in `example.env`, revoke it in the 42 developer settings and generate a replacement.
3. From the project root, install Flutter dependencies and start the backend:

```bash
flutter pub get
dart backend/server.dart
```

   Leave the backend running while using the app. If the `http` package is missing from `pubspec.yaml`, add it once with `flutter pub add http`.

## Run the app

Open a second terminal in the project root. Choose the command that matches where Flutter runs:

| Target | Command | Backend address |
| --- | --- | --- |
| Chrome on the backend computer | `flutter run -d chrome` | The app's default URL must point to the local backend. If it does not, use the explicit command below. |
| Chrome with an explicit URL | `flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8080` | Local computer |
| Android emulator | `flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080` | Host computer from the Android emulator |
| Android phone on the same network | `flutter run -d <device-id> --dart-define=API_BASE_URL=http://<computer-lan-ip>:8080` | Computer's LAN address |

Run `flutter devices` to find the Android device ID. On Linux, `ip -brief address` shows your computer's network addresses. Replace values in angle brackets before running a command. For a remote backend, use its HTTPS URL.

To open the web app in Firefox or another browser, run `flutter run -d web-server`, then open the URL printed in the terminal. Pass `--dart-define=API_BASE_URL=...` if the default address is unsuitable.

### Connect a physical Android phone

On a Samsung phone, open **Settings → About phone → Software information** and tap **Build number** seven times to enable Developer options.

**USB cable**

1. On your phone, turn on **USB debugging**, open **Settings → Developer options** and turn on **USB debugging**.
2. Unlock the phone, connect it to your computer with a USB data cable, and accept the Allow USB debugging? 
3. If the phone is not detected, open its notification panel, tap USB for charging, and select Transferring files / Android Auto.
4. Run `flutter devices`, then launch the app with the phone's device ID and your computer's LAN address as shown above.

```bash
flutter devices
flutter run -d <phone-device-id> --dart-define=API_BASE_URL=http://<computer-lan-ip>:8080
```

With USB debugging connected, you can forward backend port 8080 over USB instead of using the LAN address:

```bash
adb reverse tcp:8080 tcp:8080
flutter run -d <device-id> --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Run `adb reverse` again after reconnecting the device if needed.

**Wireless debugging (Android 11 or later)**

1. Connect the phone and computer to the same Wi-Fi network. Turn on **Wireless debugging** in Developer options.
2. Tap **Pair device with pairing code**. Use the address and pairing port shown there:

```bash
adb pair <phone-ip>:<pairing-port>
```

   Enter the displayed code when prompted.
3. Return to the main Wireless debugging screen and use its connection port, which can differ from the pairing port:

```bash
adb connect <phone-ip>:<connection-port>
flutter devices
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<computer-lan-ip>:8080
```

Your phone must be able to reach the backend computer on port 8080. Connecting ADB only installs and launches the Flutter app; it does not make the backend reachable. On a phone, `127.0.0.1` refers to the phone itself unless you use `adb reverse`. Check that the backend listens on the computer's network interface and that the network permits device-to-device connections.

### Run in an Android emulator from VS Code

Download the **Linux `.tar.gz`** from [Android Studio](https://developer.android.com/studio) for the SDK and emulator tools; you can continue editing and launching Flutter in VS Code. Extract it and launch Android Studio from its `bin` directory:

```bash
tar -xzf ~/Downloads/android-studio-*.tar.gz -C ~
~/android-studio/bin/studio
```

   If `studio` is not present, check that directory for `studio.sh`. The first-launch wizard will offer to download the Android SDK components.

1. In Android Studio, open **More Actions → SDK Manager**. Make sure an **Android SDK Platform**, **Android SDK Command-line Tools**, and **Android Emulator** are installed. 
2. Then open **More Actions → Virtual Device Manager**, Click **Create Virtual Device**, create a phone, and download its system image shown as installed in your screenshot. Click **Finish**. Start it with the **▶** button.
3. In a VS Code terminal, check that Flutter detects the running emulator:

```bash
flutter doctor
flutter devices
```

4. Start `dart backend/server.dart` in one terminal. In another, run:

```bash
flutter run -d <emulator-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

   The running emulator's device ID is listed by `flutter devices` (often `emulator-5554`). `10.0.2.2` routes from the standard Android emulator to the host computer. In later sessions, start the existing virtual device; you do not need to create it again.

Alternatively, after installing a compatible system image, create an AVD from the command line:

```bash
flutter emulators --create --name emulator-swifty
flutter emulators
flutter emulators --launch emulator-swifty
flutter devices
```

If creation reports **No suitable Android AVD system images are available**, install a system image in SDK Manager and retry. On a QEMU virtual machine, emulator startup may require nested virtualization; a physical phone is another option.

## Access token renewal (bonus)

The backend reuses an access token until shortly before it expires, then requests a new one with the client credentials. If the 42 API rejects a cached token with HTTP 401, the backend refreshes it and retries the student lookup once. Concurrent lookups share a single token request. Refresh failures return an API error without exposing credentials to the Flutter app.
