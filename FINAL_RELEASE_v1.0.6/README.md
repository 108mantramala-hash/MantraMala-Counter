# MantraMala v1.0 🙏

**MantraMala** is a beautiful and intuitive mantra counting app designed for spiritual practitioners. Track your daily chanting, meditation, and japa with an elegant, premium UI.

## ✨ Features

### Core Functionality
- **Manual Counter**: Tap the elegant button or anywhere on screen to count mantras
- **Preset Targets**: Quick selection of traditional counts (27, 54, 108)
- **Progress Tracking**: Visual circular progress indicator with gradient effects
- **Completion Status**: Clear visual feedback when targets are reached
- **Total Mantras**: Lifetime count of all mantras chanted

### Customization
- **Tap Anywhere Mode**: Enable counting by tapping anywhere on the screen
- **Sound Effects**: Optional audio feedback (bell and tap sounds)
- **Haptic Feedback**: Tactile response on each count
- **Volume Control**: Adjustable sound volume
- **Custom Targets**: Set your own daily target

### Premium UI/UX
- **Dark Theme**: Beautiful gradient-based dark interface
- **Smooth Animations**: Polished transitions and interactions
- **Responsive Design**: Adapts to different screen sizes
- **Accessibility**: Large touch targets and clear visual hierarchy

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.10.1 or higher)
- Android Studio / Xcode for mobile development
- An Android or iOS device/emulator

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd trying_flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📱 Usage

1. **Set Your Target**: Choose from preset counts (27, 54, 108) or set a custom target in Settings
2. **Start Counting**: Tap the "Tap to Count" button or enable "Tap Anywhere" mode
3. **Track Progress**: Watch the circular counter and progress percentage update
4. **Complete Session**: When you reach your target, the app celebrates your achievement
5. **Reset or Increase**: Choose to reset the counter or increase your target by the next preset

## 🎨 Customization

Access Settings via the gear icon to customize:
- Default target count
- Sound effects (on/off)
- Haptic feedback (on/off)
- Volume level
- Tap Anywhere mode

## 🛠️ Technical Details

### Built With
- **Flutter**: Cross-platform UI framework
- **just_audio**: High-quality audio playback
- **audio_session**: Audio session management
- **shared_preferences**: Local data persistence

### Architecture
- Single-page app with settings modal
- State management using StatefulWidget
- Persistent storage for progress and preferences
- Custom painters for gradient progress arcs

## 📄 License

This project is released under the MIT License - feel free to use it for personal or commercial purposes.

## 🙏 Acknowledgments

Created with devotion for spiritual practitioners worldwide. May your practice bring peace and enlightenment.

---

**Version**: 1.0.0  
**Release Date**: December 2025
