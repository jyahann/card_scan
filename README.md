# 📱 Card Scan Flutter Plugin

Flutter plugin for **scanning credit/debit cards** directly in your app.  
Supports **Android** (Google Pay OCR API) and **iOS** (native SwiftUI scanner).

## 🚀 Features

- Scan card number with camera
- Recognize expiration date
- Capture cardholder name (iOS only)

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  card_scan: ^1.0.0
```

---

## ⚙️ Setup

### Android

- Minimum `minSdkVersion`: **24**
- Connect Google Pay API for test or production
- Ensure Google account signed in on device

### iOS

- Minimum iOS version: **14.0**
- Add camera permission in `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan your card</string>
```

---

## 🔥 Usage

```dart
import 'dart:io';
import 'package:card_scan/card_scan.dart';

// Android example
if (Platform.isAndroid) {
  final result = await GoogleCardScanner.scan(testEnvironment: true);
  print(result?.number);
}

// iOS example
Stack(
  children: [
    /// Camera + scanner
    Positioned.fill(
      child: CardScan(
        bounds: bounds,
        onScanned: (event) {
          if (!isProcessed) {
            isProcessed = true;
            Navigator.of(context).pop(event); // return event
          }
        },
      ),
    ),
  ],
)

```

- `GoogleCardScanner.scan()` — Android OCR using Google Pay
- `CardScannerModal` — iOS SwiftUI scanner modal

---

## 🧪 Notes

- Android OCR requires a signed-in Google account and production access to Google Pay API.
- Use `testEnvironment: true` for test cards.
- iOS scanning works offline.
