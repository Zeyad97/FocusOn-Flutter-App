# FocusON Music - Professional Sheet Music Reader

![FocusON Music](app_icon_1024.png)

A comprehensive Flutter application designed for professional musicians, music students, and educators to read, annotate, and organize PDF sheet music with advanced practice tools and performance features.

## 🎼 Overview

FocusON Music transforms your device into a professional music stand with powerful annotation tools, practice tracking, and performance features. Built specifically for musicians who demand precision, speed, and reliability in their digital sheet music experience.

### ✨ Key Highlights
- **Zero-lag PDF rendering** optimized for live performance
- **Professional annotation system** with multi-layer support
- **Advanced practice tracking** with spot-based methodology
- **Bluetooth pedal integration** for hands-free page turning
- **Cross-platform compatibility** (Android, iOS, Windows, macOS, Linux, Web)
- **Offline-first design** for reliable performance anywhere

---

## 🚀 Features

### 📚 Comprehensive Library Management
- **Smart Import System**: Import PDFs from device storage, cloud services (Google Drive, Dropbox)
- **Intelligent Categorization**: Auto-categorize by genre with custom category support
- **Advanced Search**: Full-text search by title, composer, tags, or annotations
- **Flexible Sorting**: Sort by date, title, composer, progress, or difficulty
- **Visual Organization**: Grid and list views with customizable metadata display
- **Progress Tracking**: Visual progress indicators based on practice completion
- **Favorites System**: Star important pieces for quick access
- **Batch Operations**: Select and manage multiple pieces simultaneously

### 🎨 Professional Annotation System
- **Multi-Tool Support**: Pen, highlighter, text, stamp, and eraser tools
- **Layer Management**: Organize annotations in separate, toggleable layers
- **Color-Coded System**: Customizable color palettes for different annotation types
- **Pressure Sensitivity**: Variable line thickness and opacity support
- **Undo/Redo**: Full annotation history with unlimited undo/redo
- **Export Integration**: Save annotated PDFs with embedded or separate annotation files
- **Template Library**: Pre-defined musical symbols and frequently used annotations
- **Collaborative Features**: Share annotation layers with other users

### 🎯 Smart Practice System
- **Practice Spots**: Create targeted practice areas on any page
- **Difficulty Tracking**: Color-coded spots (red=challenging, yellow=improving, green=mastered)
- **Progress Analytics**: Track time spent, repetitions, and improvement metrics
- **Smart Recommendations**: AI-powered suggestions for practice focus areas
- **Session History**: Detailed logs of practice sessions with performance metrics
- **Goal Setting**: Set and track daily, weekly, and monthly practice goals
- **Metronome Integration**: Built-in metronome with customizable time signatures
- **Practice Dashboard**: Comprehensive overview of progress across all pieces

### 📖 Advanced PDF Viewing
- **High-Performance Rendering**: Smooth scrolling at 60fps with zero lag
- **Multiple View Modes**: Single page, two-page spread, continuous scroll, grid, list
- **Intelligent Zoom**: Smart zoom levels optimized for different content types
- **Page Navigation**: Gesture-based navigation with customizable controls
- **Full-Screen Mode**: Distraction-free reading optimized for performances
- **Night Mode**: Eye-friendly reading in low-light conditions
- **Custom Layouts**: Adjustable margins and aspect ratios
- **Bookmark System**: Quick navigation markers with custom labels

### 🎵 Performance Features
- **Bluetooth Pedal Support**: Hands-free page turning with popular pedal models
- **Auto-Scroll**: Programmable auto-scrolling based on tempo
- **Performance Mode**: Optimized UI for live performance scenarios
- **Setlist Management**: Organize pieces for concerts and recitals
- **Quick Access**: Customizable gestures for common performance actions
- **Screen Always On**: Prevent sleep during performances
- **Orientation Lock**: Maintain preferred orientation during performance

### ⚙️ Customization & Settings
- **Theme System**: Light and dark themes with custom color schemes
- **Interface Density**: Compact, standard, or spacious layout options
- **Text Scaling**: Adjustable text size for accessibility
- **Gesture Configuration**: Customize tap and swipe behaviors
- **Auto-Backup**: Automated backup of annotations and library data
- **Cloud Sync**: Synchronize library and annotations across devices
- **Privacy Controls**: Granular control over data sharing and storage

---

## 🛠️ Technical Architecture

### Core Technologies
- **Framework**: Flutter 3.7.0+ for cross-platform development
- **State Management**: Riverpod for reactive state management
- **PDF Engine**: Syncfusion Flutter PDF Viewer for professional rendering
- **Database**: SQLite (sqflite) for local data persistence
- **Cloud Integration**: Firebase for synchronization and backup
- **Bluetooth**: Flutter Bluetooth Serial for pedal integration

### Performance Optimizations
- **Lazy Loading**: Progressive PDF page loading for faster startup
- **Memory Management**: Efficient memory usage with automatic cleanup
- **Cache System**: Intelligent caching for frequently accessed content
- **Background Processing**: Non-blocking operations for smooth UI
- **Hardware Acceleration**: GPU-accelerated rendering where available

### Security & Privacy
- **Local-First**: All data stored locally by default
- **Encrypted Storage**: Sensitive data encrypted at rest
- **Secure Sync**: End-to-end encryption for cloud synchronization
- **Permission Management**: Minimal permission requests with clear justification
- **GDPR Compliance**: Full compliance with privacy regulations

---

## 📱 Platform Support

| Platform | Version | Status | Features |
|----------|---------|--------|----------|
| **Android** | 5.0+ (API 21+) | ✅ Full Support | All features including Bluetooth pedals |
| **iOS** | 12.0+ | ✅ Full Support | All features including Bluetooth pedals |
| **Windows** | Windows 10+ | ✅ Full Support | Desktop-optimized UI with keyboard shortcuts |
| **macOS** | 10.14+ | ✅ Full Support | Native macOS integration and gestures |
| **Linux** | Ubuntu 18.04+ | ✅ Beta Support | Core features with ongoing improvements |
| **Web** | Modern Browsers | 🔄 Limited Support | Core reading features, no file system access |

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: Version 3.7.0 or higher
- **Dart SDK**: Version 2.19.0 or higher
- **Platform-specific tools**:
  - Android: Android Studio with SDK 21+
  - iOS: Xcode 14+ (macOS only)
  - Desktop: Platform-specific build tools

### Quick Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Zeyad97/FocusOn-Flutter-App.git
   cd FocusOn-Flutter-App
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Platform Settings**
   ```bash
   # For Android (optional - customize app signing)
   cp android/key.properties.example android/key.properties
   
   # For iOS (optional - configure team settings)
   open ios/Runner.xcworkspace
   ```

4. **Run the Application**
   ```bash
   # Development mode with hot reload
   flutter run
   
   # Specific platform
   flutter run -d android
   flutter run -d ios
   flutter run -d windows
   flutter run -d macos
   flutter run -d linux
   flutter run -d chrome
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk --release --split-per-abi
```

**Android App Bundle (recommended for Play Store):**
```bash
flutter build appbundle --release
```

**iOS App Store:**
```bash
flutter build ios --release
```

**Windows:**
```bash
flutter build windows --release
```

**macOS:**
```bash
flutter build macos --release
```

**Linux:**
```bash
flutter build linux --release
```

**Web:**
```bash
flutter build web --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Application entry point
├── app.dart                     # Main app configuration
├── models/                      # Data models and entities
│   ├── piece.dart              # Musical piece data model
│   ├── spot.dart               # Practice spot model
│   ├── annotation.dart         # Annotation and layer models
│   ├── bookmark.dart           # Bookmark data model
│   └── user_settings.dart      # User preferences model
├── screens/                     # Application screens
│   ├── library_screen.dart     # Main library interface
│   ├── pdf_viewer/             # PDF viewing functionality
│   │   ├── pdf_score_viewer.dart    # Main PDF viewer
│   │   └── widgets/                 # PDF viewer components
│   │       ├── pdf_toolbar.dart         # Top toolbar
│   │       ├── annotation_toolbar.dart  # Annotation tools
│   │       ├── spot_overlay.dart        # Practice spots
│   │       ├── metronome_widget.dart    # Built-in metronome
│   │       └── pdf_zoom_controls.dart   # Zoom controls
│   ├── practice_dashboard_screen.dart   # Practice analytics
│   ├── favorites_screen.dart           # Favorite pieces
│   └── settings/                       # Settings screens
│       ├── settings_screen.dart        # Main settings
│       ├── appearance_settings.dart    # Theme and UI
│       ├── practice_settings.dart      # Practice preferences
│       └── sync_settings.dart          # Cloud sync options
├── services/                    # Business logic and data services
│   ├── pdf_score_service.dart   # PDF import and management
│   ├── spot_service.dart        # Practice spot operations
│   ├── annotation_service.dart  # Annotation persistence
│   ├── piece_service.dart       # Piece CRUD operations
│   ├── bluetooth_pedal_service.dart # Bluetooth integration
│   ├── cloud_sync_service.dart  # Cloud synchronization
│   └── analytics_service.dart   # Usage analytics
├── providers/                   # State management providers
│   ├── unified_library_provider.dart  # Library state
│   ├── practice_provider.dart         # Practice session state
│   ├── app_settings_provider.dart     # User settings state
│   └── annotation_provider.dart       # Annotation state
├── widgets/                     # Reusable UI components
│   ├── enhanced_components.dart # Custom enhanced widgets
│   ├── layer_panel.dart        # Annotation layer management
│   ├── annotation_filter_panel.dart # Annotation filtering
│   └── practice_widgets.dart   # Practice-specific components
├── theme/                       # Application theming
│   ├── app_theme.dart          # Main theme definitions
│   ├── colors.dart             # Color palette
│   └── typography.dart         # Text styles
├── utils/                       # Utility functions and helpers
│   ├── animations.dart         # Custom animations
│   ├── feedback_system.dart    # Haptic and audio feedback
│   ├── file_utils.dart         # File operation utilities
│   └── validation.dart         # Input validation
└── database/                    # Database schemas and operations
    ├── database_helper.dart     # SQLite database management
    ├── migrations/              # Database schema migrations
    └── repositories/            # Data access layer
```

---

## 🔧 Configuration

### Environment Setup

Create `.env` file in the project root:
```env
# Cloud Services (optional)
GOOGLE_DRIVE_API_KEY=your_google_drive_api_key
DROPBOX_API_KEY=your_dropbox_api_key

# Analytics (optional)
FIREBASE_CONFIG=your_firebase_config

# Development
DEBUG_MODE=true
LOG_LEVEL=verbose
```

### Platform-Specific Configuration

**Android (android/app/build.gradle):**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

**iOS (ios/Runner/Info.plist):**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to connect to page-turning pedals</string>
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan sheet music</string>
```

---

## 📚 Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter: sdk: flutter
  flutter_riverpod: ^2.4.0          # State management
  syncfusion_flutter_pdfviewer: ^23.1.36  # PDF rendering
  sqflite: ^2.3.0                   # Local database
  path_provider: ^2.1.0             # File system access
  file_picker: ^6.0.0               # File selection
  shared_preferences: ^2.2.0        # Simple data storage
  
dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^3.0.0             # Code quality
  build_runner: ^2.4.0              # Code generation
```

### Platform-Specific Dependencies
```yaml
# Bluetooth support
flutter_bluetooth_serial: ^0.4.0

# Cloud integration
firebase_core: ^2.15.0
firebase_auth: ^4.7.0
firebase_storage: ^11.2.0

# Enhanced UI
flutter_staggered_animations: ^1.1.1
lottie: ^2.6.0

# Analytics
firebase_analytics: ^10.4.0
```

---

## 🎯 Usage Guide

### First-Time Setup

1. **Launch the App**: Open FocusON Music on your device
2. **Complete Onboarding**: Follow the guided setup process
3. **Import Your First PDF**: Tap '+' → 'Import PDF' → Select file
4. **Explore Features**: Take the interactive tour of annotation tools

### Importing Music

**From Device Storage:**
1. Tap the '+' button in the library
2. Select 'Import from Device'
3. Browse and select PDF files
4. Add metadata (title, composer, category)

**From Cloud Services:**
1. Tap '+' → 'Import from Cloud'
2. Connect your Google Drive or Dropbox account
3. Select PDFs from cloud storage
4. Files are downloaded and imported automatically

### Creating Practice Spots

1. **Open any PDF** in the viewer
2. **Long-press** on the area you want to practice
3. **Set difficulty level** (red=challenging, yellow=improving, green=mastered)
4. **Add notes** about what to focus on
5. **Track progress** as you practice

### Using Annotations

1. **Select annotation tool** from the toolbar
2. **Choose color and size** for your annotations
3. **Draw, highlight, or add text** directly on the PDF
4. **Organize in layers** for different purposes (fingering, dynamics, etc.)
5. **Export annotated PDFs** when ready to share

### Bluetooth Pedal Setup

1. **Enable Bluetooth** on your device
2. **Go to Settings** → 'Bluetooth Pedals'
3. **Pair your pedal** following manufacturer instructions
4. **Test page turning** in any PDF
5. **Customize pedal actions** for different functions

---

## 🤝 Contributing

We welcome contributions from the musical and developer communities!

### How to Contribute

1. **Fork the Repository**
   ```bash
   git fork https://github.com/Zeyad97/FocusOn-Flutter-App.git
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/amazing-new-feature
   ```

3. **Make Your Changes**
   - Follow the existing code style
   - Add tests for new functionality
   - Update documentation as needed

4. **Commit with Clear Messages**
   ```bash
   git commit -m "feat: add support for MIDI pedal integration"
   ```

5. **Push and Create Pull Request**
   ```bash
   git push origin feature/amazing-new-feature
   ```

### Development Guidelines

- **Code Style**: Follow Dart/Flutter conventions
- **Testing**: Maintain >80% test coverage
- **Documentation**: Update README and inline comments
- **Performance**: Ensure no regressions in PDF rendering
- **Accessibility**: Support screen readers and high contrast

### Areas for Contribution

- 🎵 **Music Features**: Advanced notation support, MIDI integration
- 🎨 **UI/UX**: Enhanced animations, accessibility improvements
- 🔧 **Platform Support**: Linux optimization, web features
- 📱 **Device Integration**: Additional Bluetooth pedal support
- 🌍 **Internationalization**: Translations and localization
- 🔒 **Security**: Enhanced encryption and privacy features

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Third-Party Licenses

- **Syncfusion**: Commercial license required for commercial use
- **Flutter**: BSD-3-Clause License
- **Material Design Icons**: Apache License 2.0

---

## 🆘 Support & Community

### Getting Help

- 📖 **Documentation**: Complete guides in `/docs`
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/Zeyad97/FocusOn-Flutter-App/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/Zeyad97/FocusOn-Flutter-App/discussions)
- 💬 **Community Chat**: Discord server (link in repository)

### Frequently Asked Questions

**Q: Which file formats are supported?**
A: Currently PDF files only. MIDI and MusicXML support planned.

**Q: Can I use this app offline?**
A: Yes! FocusON Music is designed offline-first with optional cloud sync.

**Q: Which Bluetooth pedals are supported?**
A: Most HID-compatible pedals work. See compatibility list in docs.

**Q: Is my data safe and private?**
A: All data is stored locally by default. Cloud sync is optional and encrypted.

---

## 🗺️ Roadmap

### Version 2.0 (Q1 2026)
- [ ] MIDI file support and playback
- [ ] MusicXML import and export
- [ ] Advanced audio integration
- [ ] Collaborative annotation sharing
- [ ] AI-powered practice recommendations

### Version 2.1 (Q2 2026)
- [ ] Live performance recording
- [ ] Sheet music scanning with OCR
- [ ] Advanced pedal customization
- [ ] Teacher-student sharing features

### Version 3.0 (Q4 2026)
- [ ] Real-time collaboration
- [ ] Advanced analytics dashboard
- [ ] Professional music library integration
- [ ] Custom plugin system

---

## 📊 Analytics & Metrics

FocusON Music includes optional, privacy-respecting analytics to improve the app:

- **Usage Patterns**: Anonymized feature usage statistics
- **Performance Metrics**: App performance and crash reporting
- **User Feedback**: In-app feedback collection
- **Privacy First**: All analytics are opt-in and anonymized

---

## 🌟 Acknowledgments

### Special Thanks

- **Musicians** who provided feedback during development
- **Flutter Community** for excellent packages and support
- **Syncfusion** for professional PDF rendering capabilities
- **Open Source Contributors** who make this project possible

### Inspiration

This app was born from the frustration of using inadequate PDF readers during live performances and practice sessions. Built by musicians, for musicians.

---

**🎼 Built with passion for the musical community 🎼**

*"Making digital sheet music as reliable as the printed page"*

---

## 📞 Contact

- **Project Maintainer**: Zeyad97
- **Repository**: [FocusOn-Flutter-App](https://github.com/Zeyad97/FocusOn-Flutter-App)
- **Issues**: [GitHub Issues](https://github.com/Zeyad97/FocusOn-Flutter-App/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Zeyad97/FocusOn-Flutter-App/discussions)
