# Arena OVR

## 1. Project Overview
Arena OVR is a premier athlete performance tracking application designed to evaluate and elevate athletes. By combining rigorous objective testing data with a custom "Top Dawg" subjective grading curve, Arena OVR provides a comprehensive Overall Rating (OVR) for every athlete. The application serves coaches, administrators, and athletes by offering deep insights into performance metrics, dynamic rosters, and milestone-based achievements.

## 2. Tech Stack
This project is built with Flutter and relies on a robust suite of tools and Firebase backend services:

- **Framework:** [Flutter](https://flutter.dev/) (Dart)
- **State Management & Routing:** [GetX](https://pub.dev/packages/get)
- **Backend Services (Firebase):**
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Storage
  - Firebase Cloud Messaging (Push Notifications)
- **Environment Management:** `flutter_dotenv`
- **UI & Animations:** `flutter_animate`, `google_fonts`, `shimmer`, `cached_network_image`, `pin_code_fields`
- **Media & Native Capabilities:** `video_player`, `audio_session`, `image_picker`, `flutter_local_notifications`

## 3. Prerequisites & Setup
To set up the project locally for development, follow these steps:

1. **Install Flutter:** Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. **Clone the Repository:** 
   ```bash
   git clone <repository_url>
   cd Arena-OVR
   ```
3. **Environment Configuration (.env):**
   - Locate the `.env.example` file in the root directory.
   - Create a new file named `.env` in the root directory.
   - Copy the contents from `.env.example` into `.env` and fill in the required Firebase API keys and credentials.
   *(Note: The `.env` file is intentionally ignored by git for security).*
4. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

## 4. Running the App

### Android
1. Ensure you have an Android emulator running or a physical device connected with USB Debugging enabled.
2. Run the application:
   ```bash
   flutter run -d android
   ```
*(Note: Android builds utilize the standard `google-services.json` securely placed in the `android/app` directory).*

### iOS (macOS required)
1. Ensure you have Xcode installed and an iOS simulator running or an iPhone connected.
2. Navigate to the iOS directory and install CocoaPods dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```
3. Run the application:
   ```bash
   flutter run -d ios
   ```
*(Note: iOS builds utilize the standard `GoogleService-Info.plist` securely placed in the `ios/Runner` directory).*

## 5. Recent Major Features
- **Custom Subjective Top Dawg Curve:** A dynamic algorithm that calculates athlete OVRs by intelligently weighting subjective coach evaluations against standard objective testing criteria.
- **Dual-Layer Roster Filtering (Positions + Squads):** Advanced roster management allowing coaches to seamlessly filter and evaluate athletes by specific field positions or assigned custom squads.
- **OVR Milestone Badge Gates:** A transaction-based logic gate that prevents premature unlocking of high-tier OVR badges. This system ensures athletes accumulate a strict minimum threshold of verified subjective ratings before achieving elite badge status.
