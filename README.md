# Expense Tracker App

A smart personal finance and expense tracker app built with Flutter. The app helps users manage income and expenses across multiple wallets, set budgets, transfer funds, and visualize spending habits.

## Features

### Core Features
- **Dashboard**: Overview of total balance, income, expenses, and expense breakdown by category with interactive charts.
- **Multi-Wallets & Accounts**: Manage multiple money sources (Cash, Bank Account, Credit Card, Savings, or Custom Wallets) with real-time balance calculations.
- **Inter-Wallet Transfers**: Transfer money directly between wallets with instant balance updates on both sides.
- **Transactions Management**:
  - Add, edit, and delete income/expense/transfer transactions.
  - Filter transactions by category or by specific wallet.
  - Swipe-to-delete with confirmation.
- **Budgets & Alerts**:
  - Set monthly category spending limits.
  - Visual progress indicators with over-budget alerts.
- **Multi-Currency**: Support for VNĐ (`₫`), USD (`$`), EUR (`€`), JPY (`¥`), and GBP (`£`) with automatic formatting.
- **Bilingual Localization**: Switch between Tiếng Việt (🇻🇳) and English (🇬🇧) instantly on the top bar.
- **Dark Mode**: Support for Light, Dark, and System theme modes.
- **Offline Storage**: Powered by Hive NoSQL for fast, local-first data storage.

---

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- [Dart SDK](https://dart.dev) (3.x or higher)
- Editor: **VS Code** (with Flutter extension) or **Android Studio**
- Target platform: Google Chrome / Edge, Android Device / Emulator, or Windows Desktop

---

### Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd Expense-Tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

---

### Running the Project

#### 1. Running from VS Code / Android Studio
- **VS Code**: Press `F5` or go to `Run` -> `Start Debugging`. Select your target device (Chrome or Android emulator) from the bottom right status bar.
- **Android Studio**: Select your target device in the top dropdown toolbar and click the green **Run** (▶) button.

#### 2. Running from Terminal / Command Prompt

- **Web (Google Chrome - Recommended for quick testing)**:
  ```bash
  flutter run -d chrome --web-port=8080 --web-browser-flag="--user-data-dir=.chrome_data"
  ```
  *(The `--user-data-dir` flag ensures local data is kept persistently across browser restarts).*

- **Android (Physical phone connected via USB)**:
  1. Enable **Developer Options** and **USB Debugging** on your Android phone.
  2. Plug the USB cable into your computer.
  3. Run:
     ```bash
     flutter run
     ```

- **Android (Emulator)**:
  ```bash
  # Check available emulators
  flutter emulators

  # Launch emulator and run
  flutter emulators --launch Pixel_7
  flutter run -d android
  ```

- **Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

---

## Build for Production

- **Android (APK file)**:
  ```bash
  flutter build apk --release
  ```
  *Output file: `build/app/outputs/flutter-apk/app-release.apk`*

- **Android (App Bundle for Google Play Store)**:
  ```bash
  flutter build appbundle --release
  ```

- **Web**:
  ```bash
  flutter build web --release
  ```
  *Output files are generated in `build/web/`.*

---

## Architecture & Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Local Storage**: Hive (`hive_flutter`) - Type-safe NoSQL storage
- **Charts**: `fl_chart`
- **Formatting**: `intl`, `flutter_localizations`

### Project Structure

```
lib/
├── main.dart                 # App entry point & bottom navigation
├── l10n/                     # Language strings (Vietnamese & English)
├── models/                   # Data models (Transaction, Budget, Wallet, Currency)
├── providers/                # Riverpod state providers
├── screens/                  # Application screens (Dashboard, Transactions, Budgets, Wallets, Transfers)
├── services/                 # Local storage service with Hive
├── theme/                    # App color schemes and themes
├── utils/                    # Category configs and helper utilities
└── widgets/                  # Reusable UI components
```

---

## Testing

Run the test suite:

```bash
# Run all unit and widget tests
flutter test

# Run with test coverage
flutter test --coverage
```

---

## License

This project is licensed under the MIT License.
