Great! Here's an enhanced `README.md` with **badges**, **setup instructions**, and a spot for **GIF walkthroughs/screenshots**, based on your project info:

---

# 💡 Mobile Meal Planner

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)]()

A **cross-platform Flutter app** for **calendar-based meal planning**. Users can create, edit, and manage personalized meal plans, set reminders, and view stats. All data is synced and stored securely using **Firebase Firestore**.

---

## 🚀 Features Implemented

| Feature                   | Description                                                                     |
| ------------------------- | ------------------------------------------------------------------------------- |
| **✅ User Authentication** | Sign up/log in with Firebase Auth, save login, and recover forgotten passwords. |
| **📆 Meal Calendar**      | Add/edit/delete meals by name, time, and type on a calendar interface.          |
| **🔔 Notifications**      | Set meal reminders with push notifications. Includes test feature.              |
| **🍽️ Recipes**           | Browse recipes with ingredients, instructions, categories, and save favorites.  |
| **👤 Profile Edit**       | Update display name and password from the profile section.                      |
| **📊 Profile Stats**      | View total meals, favorites, weekly meals, and streaks.                         |
| **📚 Meal History**       | Review past meals with full details.                                            |
| **🌗 Theme Settings**     | Switch between light and dark mode with tips.                                   |
| **❓ Help & Support**      | Get help through FAQs and contact support via email.                            |

---

## 🛠️ Tech Stack

* **Frontend:** Flutter
* **Backend:** Firebase (Auth, Firestore, Storage, Messaging)
* **Database:** Cloud Firestore
* **State Management:** Provider
* **Local Storage:** Shared Preferences
* **Push Notifications:** `flutter_local_notifications`, `timezone`
* **Image Handling:** `image_picker`, `cached_network_image`
* **Additional Libraries:**

  * `table_calendar`
  * `flutter_markdown`
  * `url_launcher`
  * `introduction_screen`
  * `permission_handler`
  * `fluttertoast`

---

## 🧪 Setup Instructions

1. **Clone the repository**

   ```bash
   git clone https://github.com/your-username/meal_planner.git
   cd meal_planner
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   * Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the appropriate folders.
   * Enable Firebase Auth, Firestore, and Storage in your Firebase Console.

4. **Run the app**

   ```bash
   flutter run
   ```

