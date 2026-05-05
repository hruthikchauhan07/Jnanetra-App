# 👁️ Jnanetra — AI Vision Assistant

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-API%2024+-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![ONNX](https://img.shields.io/badge/ONNX-Runtime-005CED?style=for-the-badge&logo=onnx&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

**"See the world. Feel the path."**

*Jnanetra (ಜ್ಞಾನೇತ್ರ) means "Eye of Knowledge" in Sanskrit*

An AI-powered real-time assistive vision application for the visually impaired — fully offline, no internet required.

</div>

---

## 📖 Table of Contents

- [About](#-about)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [How It Works](#-how-it-works)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Navigation Logic](#-navigation-logic)
- [Model Performance](#-model-performance)
- [Design System](#-design-system)
- [Future Enhancements](#-future-enhancements)
- [Developer](#-developer)
- [License](#-license)

---

## 📱 About

**Jnanetra** is a real-time assistive navigation Android application built with Flutter. It uses on-device AI inference powered by ONNX Runtime to detect obstacles, analyze environments, and guide visually impaired users through audio announcements and haptic (vibration) feedback.

The app runs **completely offline** — no cloud, no internet, no latency. Everything happens on-device in real time.

Built for accessibility. Designed with empathy.

---

## ✨ Features

| Feature | Description | Status |
|---------|-------------|--------|
| 🔍 **Object Detection** | Detects nearby obstacles in real-time using YOLOv8n / YOLOv11n ONNX models | ✅ Live |
| 🧭 **Path Navigation** | Guides users with directional voice commands and vibration patterns | ✅ Live |
| 🌍 **Environment Analysis** | Analyzes and describes the surrounding scene with confidence score | ✅ Live |
| 👤 **Face Detection** | Detects and locates people nearby with distance estimation | ✅ Live |
| 🔊 **Audio Feedback** | Text-to-Speech announcements with 1800ms cooldown to prevent spam | ✅ Live |
| 📳 **Haptic Feedback** | Distinct vibration patterns for each navigation command | ✅ Live |
| 📴 **Fully Offline** | All inference runs on-device, zero internet dependency | ✅ Live |
| 🌙 **Screen Always On** | WakeLock keeps screen active during navigation | ✅ Live |
| 🔄 **Model Switching** | Switch between YOLOv8n and YOLOv11n at runtime | ✅ Live |

---

## 📸 Screenshots

> **6 Screens — Designed with Stitch "Visionary Clarity" Design System**

| Splash | Home | Object Detection |
|--------|------|-----------------|
| App logo with pulse animation | 4-feature grid dashboard | Live camera + bounding boxes |

| Path Navigation | Environment Analysis | Face Detection |
|----------------|---------------------|----------------|
| Large directional arrow overlay | Scanning reticle + scene description | Violet face boxes + person info |

---

## 🧠 How It Works

```
┌─────────────────────────────────────────────────────┐
│                   JNANETRA PIPELINE                  │
├─────────────────────────────────────────────────────┤
│                                                      │
│  📷 Camera Feed (CameraX, 640x480, YUV420)          │
│                      ↓                               │
│  🖼️  Frame Preprocessing                            │
│      YUV420 → RGB → 640x640 Letterbox               │
│      Normalize [0,1] → Float32List (CHW planar)     │
│                      ↓                               │
│  🤖 ONNX Inference                                  │
│      Input:  [1, 3, 640, 640]                       │
│      Output: [1, 84, 8400] → Transpose → NMS        │
│      Models: YOLOv8n / YOLOv11n                     │
│                      ↓                               │
│  🧠 Decision Engine                                 │
│      Zone Detection: LEFT / CENTER / RIGHT          │
│      Priority: CENTER > LEFT > RIGHT                │
│                      ↓                               │
│  🔊 Feedback System                                 │
│      Voice: flutter_tts (1800ms cooldown)           │
│      Haptic: Vibration patterns                     │
│                      ↓                               │
│  👤 User Output                                     │
│      Audio + Vibration + Visual Arrow Overlay       │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Frame Processing Details
- Every **3rd frame** is processed (frame skip for performance)
- `isProcessing` guard prevents **parallel inference**
- Heavy preprocessing runs in **`compute()` isolate** to keep UI at 60fps
- Target: **10–15 FPS** real-time inference on mid-range Android

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.41.x (Dart 3.11.x) |
| **ML Runtime** | flutter_onnxruntime ^1.3.0 |
| **Models** | YOLOv8n & YOLOv11n (ONNX, 640×640) |
| **Camera** | camera ^0.10.6 (CameraX) |
| **Voice** | flutter_tts ^4.2.0 |
| **Haptics** | vibration ^2.1.0 |
| **Image Processing** | image ^4.2.0 |
| **Navigation** | go_router ^14.6.2 |
| **Fonts** | google_fonts ^6.2.1 (Lexend) |
| **Permissions** | permission_handler ^11.4.0 |
| **Screen Wake** | wakelock_plus ^1.5.2 |
| **Design** | Material 3 + Stitch Visionary Clarity |
| **Platform** | Android (API 24+, arm64-v8a) |

---

## 📂 Project Structure

```
jnanetra/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml       # Permissions + hardware config
│       └── kotlin/com/jnanetra/app/
│           └── MainActivity.kt       # Flutter v2 embedding
├── assets/
│   ├── models/
│   │   ├── yolov8n.onnx             # YOLOv8 nano (640x640)
│   │   └── yolov11n.onnx            # YOLOv11 nano (640x640)
│   └── fonts/
│       └── Lexend-VariableFont.ttf  # Primary typeface
├── lib/
│   ├── main.dart                    # App entry, permissions, router
│   ├── app_theme.dart               # Design system (colors, typography)
│   ├── screens/
│   │   ├── splash_screen.dart       # Animated logo → auto navigate
│   │   ├── home_screen.dart         # 4-feature dashboard grid
│   │   ├── object_detection_screen.dart    # Live YOLO detection
│   │   ├── path_navigation_screen.dart     # Directional guidance
│   │   ├── environment_analysis_screen.dart # Scene analysis
│   │   └── face_detection_screen.dart      # Person detection
│   ├── ml/
│   │   ├── onnx_detector.dart       # ONNX session + YOLO postprocessing
│   │   └── detection.dart           # Detection data class + enums
│   ├── engine/
│   │   └── decision_engine.dart     # Zone-based navigation logic
│   ├── camera/
│   │   └── camera_manager.dart      # CameraX wrapper + frame skipping
│   ├── feedback/
│   │   └── feedback_manager.dart    # TTS + vibration with cooldown
│   ├── widgets/
│   │   ├── bounding_box_painter.dart # CustomPainter for detection boxes
│   │   ├── direction_indicator.dart  # Animated directional arrow
│   │   ├── face_box_painter.dart     # Violet face detection overlay
│   │   └── feature_card.dart         # Home screen feature cards
│   └── utils/
│       └── image_utils.dart          # YUV→RGB, letterbox, rescale
├── pubspec.yaml
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.x stable
- Android Studio (Meerkat / Ladybug or newer)
- Android device with API 24+ (Android 7.0+)
- USB Debugging enabled on device

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/hruthikchauhan07/Jnanetra-App.git
cd Jnanetra-App

# 2. Install Flutter dependencies
flutter pub get

# 3. Place ONNX model files (get from Releases or train your own)
mkdir -p assets/models/
cp /path/to/yolov8n.onnx assets/models/yolov8n.onnx
cp /path/to/yolov11n.onnx assets/models/yolov11n.onnx

# 4. Accept Android licenses
flutter doctor --android-licenses

# 5. Connect your Android device and run
flutter devices                        # Find your device ID
flutter run -d <device-id>             # Run in debug mode

# 6. Build release APK
flutter build apk --release
```

### Android Permissions Required

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
```

---

## 🧭 Navigation Logic

The screen is divided into **3 detection zones**:

```
┌───────────┬──────────────────┬───────────┐
│           │                  │           │
│   LEFT    │     CENTER       │   RIGHT   │
│   0–30%   │    30–70%        │  70–100%  │
│           │                  │           │
└───────────┴──────────────────┴───────────┘
```

### Decision Priority

```
IF obstacle in CENTER  →  🛑 "Stop! Obstacle ahead"     [long vibration: 600ms]
IF obstacle in LEFT    →  ➡️  "Move right"               [double short: 150-100-150ms]
IF obstacle in RIGHT   →  ⬅️  "Move left"                [triple short: 100-80-100-80-100ms]
IF no obstacle         →  ⬆️  "Path clear. Move forward" [gentle pulse: 80ms]
```

### Target Detection Classes (COCO)

| Class ID | Label | Priority |
|----------|-------|----------|
| 0 | person | 🔴 High |
| 56 | chair | 🟠 Medium |
| 57 | couch | 🟠 Medium |
| 59 | bed | 🟠 Medium |
| 60 | dining table | 🟠 Medium |
| 61 | toilet | 🟠 Medium |
| 39 | bottle | 🔵 Low |
| 63 | laptop | 🔵 Low |
| 24 | backpack | 🔵 Low |
| 26 | handbag | 🔵 Low |

---

## 📊 Model Performance

| Model | File Size | COCO mAP50 | Est. FPS (mid-range Android) | Input |
|-------|-----------|------------|------------------------------|-------|
| **YOLOv8n** | ~6 MB | 37.3% | 15–18 FPS | 640×640 |
| **YOLOv11n** | ~6 MB | 39.5% | 14–17 FPS | 640×640 |

### ONNX Tensor Specs

```
Input:
  Name:  "images"
  Shape: [1, 3, 640, 640]   (batch, channels, height, width)
  Type:  Float32
  Order: CHW planar (RRRR...GGGG...BBBB...)

Output:
  Name:  "output0"
  Shape: [1, 84, 8400]      (batch, attributes, anchors)
  Type:  Float32
  Format: [cx, cy, w, h, class_0...class_79] per anchor
```

---

## 🎨 Design System

Built with **Stitch "Visionary Clarity"** — an accessibility-first design system.

### Color Palette

| Token | Color | Usage |
|-------|-------|-------|
| `primary` | `#0058BC` | Object Detection, Brand |
| `secondary` | `#006E2D` | Path Navigation |
| `tertiary` | `#9E3D00` | Environment Analysis |
| `face` | `#7C3AED` | Face Detection |
| `error` | `#BA1A1A` | Stop / Danger |
| `background` | `#F9F9FF` | App background |
| `onSurface` | `#181C23` | Primary text |

### Typography
- **Font:** Lexend (Variable) via Google Fonts
- **Min body size:** 18sp (WCAG AA compliant)
- **Min tap target:** 64dp on all interactive elements

---

## 🔮 Future Enhancements

- [ ] **YOLOv10** integration (NMS-free, faster postprocessing)
- [ ] **Depth estimation** using MiDaS for accurate distance measurement
- [ ] **Voice commands** ("detect objects", "describe environment")
- [ ] **Multi-language TTS** (Kannada, Hindi, Tamil support)
- [ ] **Night mode** with low-light camera enhancement
- [ ] **Occupancy grid mapping** for path planning
- [ ] **A\* pathfinding** for indoor navigation
- [ ] **Cloud-edge hybrid** for complex scene understanding
- [ ] **Wear OS companion** app for wrist haptics
- [ ] **BLE beacon** integration for indoor positioning

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

```bash
# Fork the repo, then:
git checkout -b feature/your-feature-name
git commit -m "Add your feature"
git push origin feature/your-feature-name
# Open a Pull Request
```

---

## 👨‍💻 Developer

<div align="center">

**Hruthik Chauhan**

[![GitHub](https://img.shields.io/badge/GitHub-hruthikchauhan07-181717?style=for-the-badge&logo=github)](https://github.com/hruthikchauhan07)

*Built with ❤️ for accessibility — because technology should empower everyone.*

</div>

---

## 📄 License

```
MIT License

Copyright (c) 2026 Hruthik Chauhan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```

---

<div align="center">

*Jnanetra — Eye of Knowledge* 👁️

**See the world. Feel the path.**

</div>
