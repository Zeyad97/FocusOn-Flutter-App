# FocusON Music App - Code Explanation

This document provides a detailed explanation of every major file, page, and line of code in the FocusON Music App. It is designed to help developers and contributors understand the architecture, logic, and flow of the application.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Main Files](#main-files)
3. [Screens](#screens)
4. [Models](#models)
5. [Services](#services)
6. [Widgets](#widgets)
7. [State Management](#state-management)
8. [PDF & Annotation System](#pdf--annotation-system)
9. [Practice & Spot System](#practice--spot-system)
10. [App Theme & Settings](#app-theme--settings)
11. [File-by-File Breakdown](#file-by-file-breakdown)
12. [How to Read This Document](#how-to-read-this-document)

---

## Project Overview
FocusON Music is a cross-platform Flutter app for musicians to read, annotate, and organize PDF sheet music. It features:
- Library management
- PDF viewing and annotation
- Practice spot creation
- Favorites and bookmarks
- Metronome and performance tools
- Data persistence and cloud import

---

## Main Files
- `main.dart`: App entry point, theme setup, navigation.
- `app.dart`: Main app widget, navigation logic.
- `pubspec.yaml`: Dependency and asset configuration.
- `README.md`: Project overview and setup instructions.
- `CODE_EXPLANATION.md`: This documentation file.

---

## Screens
- `library_screen.dart`: Main library UI, PDF list, search, sort, import.
- `pdf_score_viewer.dart`: PDF viewing, annotation, spot creation, metronome.
- `settings_screen.dart`: App settings, theme, preferences.
- `favorites_screen.dart`: Favorite pieces collection.
- `practice_dashboard_screen.dart`: Practice stats and dashboard.

---

## Models
- `piece.dart`: Music piece data model.
- `spot.dart`: Practice spot model.
- `annotation.dart`: Annotation and layer models.
- `bookmark.dart`: Bookmark model.

---

## Services
- `pdf_score_service.dart`: PDF import and management.
- `spot_service.dart`: Practice spot CRUD operations.
- `annotation_service.dart`: Annotation CRUD and layer management.
- `piece_service.dart`: Piece CRUD and metadata.
- `bluetooth_pedal_service.dart`: Pedal integration for page turning.

---

## Widgets
- `pdf_toolbar.dart`: Top toolbar for PDF viewer.
- `spot_overlay.dart`: Overlay for displaying and managing practice spots.
- `annotation_toolbar.dart`: Annotation tools and color selection.
- `metronome_widget.dart`: Metronome for practice.
- `pdf_zoom_controls.dart`: Zoom controls for PDF viewer.
- `layer_panel.dart`: Annotation layer management.
- `annotation_filter_panel.dart`: Annotation filtering UI.

---

## State Management
- Uses Riverpod and Provider for state management.
- Providers for library, pieces, practice, settings, and user data.

---

## PDF & Annotation System
- Uses Syncfusion PDF Viewer for high-performance PDF rendering.
- Annotation system supports pen, highlighter, text, stamp, and eraser tools.
- Layered annotation architecture for advanced editing.
- Annotation data is persisted in local database.

---

## Practice & Spot System
- Practice spots can be created on any PDF page.
- Spots are color-coded by difficulty and readiness.
- Spots are saved to the database and shown in the practice dashboard.
- Drag-and-drop and editing supported for spots.

---

## App Theme & Settings
- Customizable theme (light/dark).
- User preferences for interface density, text scale, and more.
- Settings screen for all app options.

---

## File-by-File Breakdown
### main.dart
- Sets up the ProviderScope for Riverpod.
- Configures MaterialApp with theme, navigation, and splash screen.
- Handles theme switching and interface density.

### library_screen.dart
- Displays the music library with search, sort, and import features.
- Uses Riverpod providers for library and pieces.
- Handles favorite toggling, progress updates, and piece import.
- UI includes animated app bar, quick stats, search bar, sort dropdown, and grid/list of pieces.
- Each piece card shows title, composer, progress, pages, and spot colors.

### pdf_score_viewer.dart
- Main PDF viewing screen with Syncfusion PDF Viewer.
- Handles page navigation, zoom, annotation, and spot creation.
- Annotation system supports pen, highlighter, text, stamp, eraser, and layers.
- Practice spots can be created, edited, and moved.
- Metronome widget for practice.
- Bluetooth pedal integration for page turning.

### models/piece.dart
- Defines the Piece class with fields for id, title, composer, difficulty, pages, spots, and metadata.
- Includes methods for copying, updating, and serializing pieces.

### models/spot.dart
- Defines the Spot class for practice spots.
- Fields for id, pieceId, title, description, pageNumber, coordinates, color, priority, readiness, timestamps.
- Methods for copying, updating, and serializing spots.

### models/annotation.dart
- Defines Annotation, AnnotationLayer, and related classes.
- Supports multiple annotation tools and color tags.
- Layer management for advanced annotation workflows.

### services/pdf_score_service.dart
- Handles PDF import from device and cloud.
- Converts files to Piece objects and saves metadata.

### services/spot_service.dart
- CRUD operations for practice spots.
- Database integration for spot persistence.

### services/annotation_service.dart
- CRUD operations for annotations and layers.
- Database integration for annotation persistence.

### widgets/spot_overlay.dart
- Displays practice spots on top of the PDF viewer.
- Handles spot tap, long press, drag, and creation dialogs.

### widgets/annotation_toolbar.dart
- UI for selecting annotation tools, colors, and layers.

### widgets/metronome_widget.dart
- Metronome for practice sessions.

---

## How to Read This Document
- Each section explains the purpose and logic of the corresponding file or feature.
- For detailed line-by-line explanations, see the inline comments in the Dart files.
- Use this document as a reference for understanding, contributing, or debugging the app.

---

## PDF Copy
To generate a PDF, use any Markdown-to-PDF converter (e.g., VS Code extension, Pandoc, or online tools) with this file.

---

**For further questions, see the README.md or contact the development team.**
