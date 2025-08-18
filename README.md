# Music Sheet Reader

A cross-platform Flutter application specifically designed for musicians to read and organize PDF sheet music.

## Features

### 📚 Library Management
- **Import PDFs**: Easily import PDF sheet music from your device
- **Categories**: Organize your music into categories (Classical, Jazz, Pop, Folk, Other, and custom categories)
- **Search & Filter**: Filter by categories and sort by recent usage
- **Metadata**: Track when files were added and last opened

### 🔖 Bookmarks & Favorites
- **Favorites**: Mark important pieces as favorites for quick access
- **Bookmarks**: Add page bookmarks within PDFs for easy navigation
- **Quick Access**: Dedicated favorites screen for frequently used pieces

### 📖 PDF Viewing
- **Smooth Reading**: High-quality PDF rendering optimized for music sheets
- **Full-Screen Mode**: Distraction-free reading perfect for live performance
- **Page Navigation**: Swipe or tap to navigate through pages
- **Zoom Control**: Pinch to zoom for detailed viewing
- **Page Counter**: Always know which page you're on

### ⚙️ Settings & Customization
- **Keep Screen On**: Prevent screen timeout while reading
- **Dark Mode**: Better reading experience in low light
- **Default Zoom**: Set your preferred zoom level
- **Category Management**: Add or remove custom categories
- **Data Management**: Clear all data when needed

## Getting Started

### Prerequisites
- Flutter SDK (>=3.8.0)
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd music_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## App Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # Main app widget with navigation
├── models/                # Data models
│   ├── pdf_document.dart  # PDF document model
│   └── bookmark.dart      # Bookmark model
├── screens/               # UI screens
│   ├── library_screen.dart    # Main library with PDF list
│   ├── favorites_screen.dart  # Favorites collection
│   ├── settings_screen.dart   # App settings
│   └── pdf_viewer_screen.dart # PDF reading interface
├── services/              # Business logic
│   ├── storage_service.dart   # Local data persistence
│   └── pdf_service.dart       # PDF file operations
└── widgets/               # Reusable UI components
    └── pdf_list_item.dart     # PDF list item widget
```

## Dependencies

- **syncfusion_flutter_pdfviewer**: High-performance PDF viewing
- **file_picker**: Import PDFs from device storage
- **shared_preferences**: Local data storage
- **path_provider**: File system access
- **permission_handler**: Handle storage permissions

## Usage Guide

### Adding Your First PDF
1. Open the app and go to the Library tab
2. Tap the '+' button in the top-right corner
3. Select a PDF file from your device
4. The PDF will be imported and ready to read

### Organizing Your Music
1. Long-press or use the menu on any PDF to edit it
2. Change the title or category as needed
3. Use the category filters at the top of the Library to find music quickly

### Reading Sheet Music
1. Tap any PDF to open it in the viewer
2. Swipe left/right or tap the edges to turn pages
3. Tap the full-screen button for distraction-free reading
4. Add bookmarks by tapping the bookmark icon
5. Mark as favorite using the heart icon

### Performance Mode
- Use full-screen mode during performances
- Enable "Keep Screen On" in settings to prevent screen timeout
- Organize your performance pieces in a dedicated category

## Cross-Platform Support

This app runs on:
- ✅ Android (API 21+)
- ✅ iOS (iOS 11+)
- ✅ Windows (Windows 10+)
- ✅ macOS (macOS 10.14+)
- ✅ Linux (Ubuntu 18.04+)
- ✅ Web (Chrome, Firefox, Safari, Edge)

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue on GitHub or contact the development team.

---

**Built with ❤️ for musicians by musicians**
