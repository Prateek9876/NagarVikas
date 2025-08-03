# 🛠️ CONTRIBUTING GUIDELINES – NagarVikas

Welcome to **NagarVikas**! 🇮🇳
We're excited about your interest in contributing to this civic-tech project that helps Indian citizens raise and resolve local issues.

Whether you're here via GSSoC or independently, your contribution is valuable! 🙌

Please make sure to also read and follow our [Code of Conduct](CODE_OF_CONDUCT.md). ��🏽‍🥶

---

## 📌 What You Can Work On

We welcome contributions in the following areas:

* 🐞 Bug Fixes
* ✨ New Features
* 🎨 UI/UX Enhancements
* 📄 Documentation
* 🔐 Firebase/Cloudinary Setup Improvements
* 🧪 Adding Unit/Widget Tests

---

## 🚀 Getting Started

### 1. 🍴 Fork the Repository

Click on the **Fork** button at the top-right of the repo.

### 2. 📅 Clone Your Fork Locally

```bash
git clone https://github.com/<your-username>/NagarVikas.git
cd NagarVikas
```

### 3. 📦 Install Dependencies

```bash
flutter pub get
```

---

## 🔥 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable:

   * Authentication (Email/Password)
   * Realtime Database
4. Download `google-services.json` and place it inside:

```bash
android/app/google-services.json
```

Update `android/build.gradle`:

```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

Update `android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

Add to `pubspec.yaml`:

```yaml
# Add firebase_core, firebase_auth, and firebase_database packages
```

---

## ☁️ Cloudinary Setup

1. Create an account at [https://cloudinary.com](https://cloudinary.com)
2. Note down:

   * Cloud name
   * API Key
   * API Secret
3. Use these in your Cloudinary service files (`lib/services/...`)

Add to `pubspec.yaml`:

```yaml
# Add http package
```

---

## 📍 Geolocator (Location Plugin)

Add to `pubspec.yaml`:

```yaml
# Add geolocator and geocoding packages
```

### AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (Info.plist):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to report the issue.</string>
```

---

## 🔔 Notifications (OneSignal or FCM)

1. Setup OneSignal app
2. Add Firebase Server Key
3. Get OneSignal App ID

Add to `pubspec.yaml`:

```yaml
# Add onesignal_flutter package
```

Initialize in `main.dart`:

```dart
await OneSignal.shared.setAppId("YOUR_ONESIGNAL_APP_ID");
```

Permissions:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

---

## 🌫️ Optional: Dialogflow (for voice complaints)

Use package: `dialogflow_flutter` with service account JSON (if integrated).

---

## 🧳 Folder Structure Overview

| Folder/File                | Purpose                                   |
| -------------------------- | ----------------------------------------- |
| `lib/`                     | Main application logic and UI code        |
| `assets/`                  | Images, icons, static resources           |
| `android/`, `ios/`         | Platform-specific code                    |
| `functions/`               | (Optional) Firebase Cloud Functions       |
| `.github/`                 | GitHub workflows, issue templates, etc.   |
| `test/`                    | Unit and widget tests                     |
| `firebase.json`            | Firebase project settings                 |
| `pubspec.yaml`             | Flutter dependencies and asset references |
| `README.md`                | Project overview and setup                |
| `CODE_OF_CONDUCT.md`       | Community behavior standards              |
| `PULL_REQUEST_TEMPLATE.md` | Pull request format                       |

---

## 🌿 Contribution Process

### 1. Create a New Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Your Changes

Follow Flutter best practices and keep code clean and modular.

### 3. Commit and Push

```bash
git add .
git commit -m "✨ Added feature: your feature description"
git push origin feature/your-feature-name
```

### 4. Create Pull Request

* Go to your forked repo on GitHub
* Click on **Compare & pull request**
* Add details and link the related issue (if any)
* Submit your PR!

---

## ✅ Best Practices

* Follow Dart/Flutter conventions
* Test your code before making a PR
* Use meaningful commit messages
* Make small, modular PRs

---

## 💬 Need Help?

Reach out to the project maintainer:
**Prateek Chourasia** – [prateekchourasia9876@gmail.com](mailto:prateekchourasia9876@gmail.com)

---

## 💖 Thank You!

Thanks for being here and contributing to NagarVikas. Your help makes this project better for citizens and communities alike.

> *"Let’s build civic-tech that drives real change."* 🧱

Happy coding! 🚀
