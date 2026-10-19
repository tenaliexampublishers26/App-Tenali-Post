# SETUP.md — Tenali Post Local Developer Setup Guide

This guide explains how to open, configure, run, and test **Tenali Post** on your local Windows development machine.

---

## 1. Project Location & Toolchain
- **Project Path:** `C:\Users\Team3\OneDrive\Desktop\tenali post`
- **Flutter SDK:** Installed at `C:\Users\Team3\flutter` (`bin` added to User PATH)
- **Dart SDK:** Bundled with Flutter (`3.13.5`)

To verify the Flutter installation in PowerShell:
```powershell
flutter --version
flutter doctor
```

---

## 2. Setting Up Android Studio & Android SDK (Required for Android builds)

Since the Android SDK is not yet installed on this PC, follow these simple steps to enable Android builds and emulation:

1. **Download Android Studio:**
   - Download the official installer from [developer.android.com/studio](https://developer.android.com/studio).
   - Alternatively, install via winget in PowerShell:
     ```powershell
     winget install Google.AndroidStudio
     ```
2. **Complete the Android Studio Setup Wizard:**
   - Run Android Studio and choose the **Standard** setup type.
   - It will automatically download the **Android SDK (API 34)**, **Android SDK Command-line Tools**, and **Android SDK Build-Tools**.
3. **Accept Android Licenses:**
   - In PowerShell, run:
     ```powershell
     flutter doctor --android-licenses
     ```
   - Press `y` to accept each license.
4. **Create an Android Virtual Device (Emulator):**
   - In Android Studio, open the **Virtual Device Manager** (Device Manager).
   - Click **Create Device**, select **Pixel 8** or **Pixel 7**, and choose system image **API 34 (UpsideDownCake)** or **API 33**.
   - Click **Finish**.

---

## 3. Running the App

### Option A: On an Android Emulator or Physical Device
Once Android Studio and an emulator are configured:
```powershell
# List available devices
flutter devices

# Run the app on Android
flutter run
```

If multiple devices are connected:
```powershell
flutter run -d <device-id>
```

### Option B: On Google Chrome / Web (For rapid UI preview)
```powershell
flutter run -d chrome
```

---

## 4. Supabase Backend Configuration

Tenali Post operates in its own dedicated Supabase project, completely separate from the existing e-commerce website.

### Environment Configuration
When your dedicated Supabase project is created:
1. Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=https://your-tenali-post-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-publishable-key
   ```
2. In Google Cloud Console, configure the OAuth redirect URI for Android:
   - Scheme: `tenalipost`
   - Host: `login-callback`
   - Complete redirect URL: `tenalipost://login-callback`

*Note: If no Supabase credentials are provided, Tenali Post automatically launches in offline/demonstration mode with complete sample MTS, Postman, and PA/SA syllabus data.*

---

## 5. Testing & Verification Commands

```powershell
# Fetch dependencies
flutter pub get

# Run static code analysis (must show 0 issues)
flutter analyze

# Run automated unit and model tests
flutter test

# Build debug Android APK (once Android SDK is installed)
flutter build apk --debug
```

---

## 6. Safe Development Workflow
- **Keep all work local:** Never run `git push origin main` without explicit authorization.
- **Isolate backends:** Never point Supabase credentials to the production e-commerce database.
- **Reread documentation:** Review `AGENTS.md` and `PROJECT_CONTEXT.md` before making architectural changes.