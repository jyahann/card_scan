# Card Scan Flutter Plugin

Flutter plugin for **scanning credit/debit cards** directly in your app.  
Supports **Android** (Google Pay OCR API) and **iOS** (native SwiftUI scanner).

## 🚀 Features

- Scan card number with camera
- Recognize expiration date
- Capture cardholder name (iOS only)

---

## ⚙️ Setup

### Android

- Connect Google Pay API for test or production
- Ensure Google account signed in on device

### iOS

- Minimum iOS version: **13.0**
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

// Android usage example
if (Platform.isAndroid) {
  final result = await GoogleCardScanner.scan(testEnvironment: true);
  print(result?.number);
}

// iOS camera view example
Stack(
  children: [
    /// Camera + scanner
    Positioned.fill(
      child: CardScan(
        onScanned: (event) {
          if (!isProcessed) {
            isProcessed = true;
            Navigator.of(context).pop(event); // return event
          }
        },
      ),
    ),

    // Custom overlay here
  ],
)

```

- `GoogleCardScanner.scan()` — Android OCR using Google Pay
- `CardScannerModal` — iOS SwiftUI camera view

---

## 🧪 Notes

- Android OCR requires a signed-in Google account and production access to Google Pay API.
- Use `testEnvironment: true` for test cards.
- iOS scanning works offline.
