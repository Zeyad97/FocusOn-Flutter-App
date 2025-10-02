# Software Requirements Specification (SRS)
**Version 1.0**  
**Date: 2025-10-1**

## Table of Contents
1. Introduction
   1.1 Purpose
   1.2 Scope
   1.3 Definitions, Acronyms, and Abbreviations
   1.4 References
   1.5 Overview

2. Overall Description
   2.1 Product Perspective
   2.2 Product Functions
   2.3 User Classes and Characteristics
   2.4 Operating Environment
   2.5 Design and Implementation Constraints
   2.6 User Documentation
   2.7 Assumptions and Dependencies

3. System Features (Functional Requirements)
   3.1 Library Management
   3.2 PDF Viewing
   3.3 Annotation System
   3.4 Practice Spots
   3.5 Metronome Integration
   3.6 Settings and Customization
   3.7 Data Export and Import

4. External Interface Requirements
   4.1 User Interfaces
   4.2 Hardware Interfaces
   4.3 Software Interfaces
   4.4 Communications Interfaces

5. Non-functional Requirements
   5.1 Performance Requirements
   5.2 Security Requirements
   5.3 Usability Requirements
   5.4 Reliability and Availability
   5.5 Maintainability
   5.6 Portability

6. Appendices
   6.1 Glossary
   6.2 Diagrams
   6.3 References

---

## 1. Introduction

### 1.1 Purpose
This Software Requirements Specification (SRS) document describes the functional and non-functional requirements for the FocusON Music App, a cross-platform Flutter application designed for musicians to read, annotate, and organize PDF sheet music.

### 1.2 Scope
FocusON Music App is a comprehensive digital sheet music management system that allows musicians to:
- Import and organize PDF sheet music
- Annotate scores with multiple tools and layers
- Create practice spots with difficulty tracking
- Use integrated metronome for practice
- Sync progress across devices
- Export and share annotated scores

### 1.3 Definitions, Acronyms, and Abbreviations
- **MVVM**: Model-View-ViewModel architecture
- **CRUD**: Create, Read, Update, Delete
- **UI**: User Interface
- **PDF**: Portable Document Format
- **BPM**: Beats Per Minute
- **SQLite**: Embedded database engine
- **Riverpod**: State management library for Flutter
- **Syncfusion**: Third-party PDF viewing library

### 1.4 References
- https://github.com/Zeyad97/FocusOn-Flutter-App
- Flutter Documentation: https://docs.flutter.dev
- Syncfusion PDF Viewer: https://help.syncfusion.com/flutter/pdf-viewer

### 1.5 Overview
This document provides a comprehensive specification for the FocusON Music App, covering all functional and non-functional requirements. It serves as a guide for developers, testers, and stakeholders involved in the project.

---

## 2. Overall Description

### 2.1 Product Perspective
The FocusON Music App is a standalone mobile application built with Flutter and Dart, using Syncfusion PDF Viewer for document rendering and SQLite for local data storage. It follows MVVM architecture with Riverpod state management and Material Design guidelines.

### 2.2 Product Functions
- PDF sheet music library management
- Advanced PDF viewing with zoom and navigation
- Multi-layer annotation system (pen, highlighter, text, stamps)
- Practice spot creation and management
- Integrated metronome with customizable settings
- Favorites and bookmarks system
- Practice progress tracking and analytics
- Data export and import capabilities
- Theme customization and user preferences
- Bluetooth pedal integration for hands-free operation

### 2.3 User Classes and Characteristics
- **Student Musicians**: Need practice tracking, spot creation, and progress monitoring
- **Professional Musicians**: Require advanced annotation tools and performance features
- **Music Teachers**: Need to annotate and share scores with students

### 2.4 Operating Environment
- **Android**: 5.0+ (API level 21+)
- **iOS**: 12.0+
- **Windows**: Windows 10+
- **macOS**: macOS 10.14+
- **Linux**: Ubuntu 18.04+
- **Internet connection**: Optional for cloud features
- **Compatible with Flutter SDK**: 3.7.0+

### 2.5 Design and Implementation Constraints
- Must use Flutter framework and Dart programming language
- Syncfusion PDF Viewer required for PDF rendering
- SQLite database for local data persistence
- Adherence to Material Design guidelines
- Cross-platform compatibility required
- Offline-first functionality

### 2.6 User Documentation
- In-app onboarding and tutorial screens
- CODE_EXPLANATION.md
- README.md
- User manual and help documentation

### 2.7 Assumptions and Dependencies
- Users have basic mobile device operation skills
- Device has sufficient storage for PDF files
- Users understand basic music notation
- Flutter SDK availability and updates
- Syncfusion PDF Viewer license compliance
- Platform-specific permissions (file access, storage)

---

## 3. System Features (Functional Requirements)

### 3.1 Library Management
Users can import, organize, and manage their PDF sheet music collection.

**Functional Requirements:**
- **FR-1**: The system shall allow users to import PDF files from device storage
- **FR-2**: The system shall allow users to import PDF files from cloud storage
- **FR-3**: The system shall display library with grid and list view options
- **FR-4**: The system shall provide search functionality by title, composer, or tags
- **FR-5**: The system shall allow sorting by title, composer, date added, or progress
- **FR-6**: The system shall display piece metadata (title, composer, pages, difficulty)
- **FR-7**: The system shall allow users to mark pieces as favorites
- **FR-8**: The system shall track practice progress for each piece

### 3.2 PDF Viewing
Users can view PDF sheet music with advanced navigation and zoom controls.

**Functional Requirements:**
- **FR-9**: The system shall display PDF files with high-quality rendering
- **FR-10**: The system shall support zoom in/out functionality
- **FR-11**: The system shall support page navigation (next/previous)
- **FR-12**: The system shall display current page number and total pages
- **FR-13**: The system shall support page jumping to specific page numbers
- **FR-14**: The system shall maintain zoom level across page changes
- **FR-15**: The system shall support landscape and portrait orientations

### 3.3 Annotation System
Users can annotate PDF scores with various tools and organize annotations in layers.

**Functional Requirements:**
- **FR-16**: The system shall provide pen tool for freehand drawing
- **FR-17**: The system shall provide highlighter tool for text highlighting
- **FR-18**: The system shall provide text tool for adding text annotations
- **FR-19**: The system shall provide stamp tool for predefined symbols
- **FR-20**: The system shall provide eraser tool for removing annotations
- **FR-21**: The system shall support multiple annotation layers
- **FR-22**: The system shall allow layer visibility toggling
- **FR-23**: The system shall support annotation color selection

### 3.4 Practice Spots
Users can create practice spots on specific areas of sheet music pages.

**Functional Requirements:**
- **FR-24**: The system shall allow users to create practice spots by tapping on PDF
- **FR-25**: The system shall allow users to set spot title and description
- **FR-26**: The system shall allow users to set spot difficulty level
- **FR-27**: The system shall allow users to set spot readiness status
- **FR-28**: The system shall display spots as colored overlays on PDF pages
- **FR-29**: The system shall allow spot editing and repositioning
- **FR-30**: The system shall track spot practice statistics

### 3.5 Metronome Integration
Built-in metronome for practice sessions.

**Functional Requirements:**
- **FR-31**: The system shall provide adjustable tempo (30-300 BPM)
- **FR-32**: The system shall support time signature selection
- **FR-33**: The system shall provide visual and audio metronome beats
- **FR-34**: The system shall allow volume adjustment
- **FR-35**: The system shall persist metronome settings per piece

### 3.6 Settings and Customization
Users can customize app settings and preferences.

**Functional Requirements:**
- **FR-36**: The system shall allow users to switch between dark and light themes
- **FR-37**: The system shall allow users to adjust text scale factor
- **FR-38**: The system shall allow users to configure interface density
- **FR-39**: The system shall allow users to manage Bluetooth pedal settings

### 3.7 Data Export and Import
Users can export and import their data and annotations.

**Functional Requirements:**
- **FR-40**: The system shall allow users to export annotated PDFs
- **FR-41**: The system shall allow users to export practice data
- **FR-42**: The system shall allow users to backup library data
- **FR-43**: The system shall allow users to share pieces and annotations

---

## 4. External Interface Requirements

### 4.1 User Interfaces
- **Library Screen**: Grid/list view of PDF collection, search and sort functionality
- **PDF Viewer Screen**: Full-screen PDF display with annotation tools and controls
- **Practice Dashboard**: Progress tracking, statistics, and practice history
- **Settings Screen**: App preferences, theme selection, and configuration options
- **Favorites Screen**: Quick access to marked favorite pieces
- **Onboarding Screen**: Introduction and tutorial for new users

### 4.2 Hardware Interfaces
- Android/iOS device with touch interface
- Bluetooth connectivity for pedal integration
- Device storage for PDF files and data
- Audio output for metronome functionality

### 4.3 Software Interfaces
- **Syncfusion PDF Viewer API**: For PDF rendering and display
- **SQLite Database**: For local data persistence
- **Device File System**: For PDF import and storage
- **Cloud Storage APIs**: For Google Drive and Dropbox integration
- **Bluetooth APIs**: For pedal connectivity

### 4.4 Communications Interfaces
- **HTTPS**: For secure cloud communications
- **Bluetooth protocols**: For pedal communication
- **Local network**: For device-to-device sharing (optional)

---

## 5. Non-functional Requirements

### 5.1 Performance Requirements
- App should load library and display within 3 seconds
- PDF opening time should not exceed 5 seconds for files under 10MB
- Page navigation should respond within 500ms
- Annotation drawing should have latency under 100ms
- App should maintain 60 FPS during normal operation

### 5.2 Security Requirements
- All user data is stored locally by default
- Cloud sync data is encrypted during transmission
- App follows platform-specific security guidelines
- No unauthorized access to user files or annotations
- Secure handling of Bluetooth communications

### 5.3 Usability Requirements
- Intuitive UI with clear navigation
- Comprehensive onboarding for new users
- Contextual help and error feedback
- Accessibility support for users with disabilities
- Consistent design across all platforms

### 5.4 Reliability and Availability
- App should have 99.5% uptime during normal usage
- Automatic data backup and recovery mechanisms
- Graceful handling of network connectivity issues
- Robust error handling and user feedback

### 5.5 Maintainability
- Modular codebase with clear separation of concerns
- Comprehensive code documentation and comments
- Automated testing suite with high coverage
- Version control and continuous integration

### 5.6 Portability
- Compatible with Android 5.0+ devices
- Compatible with iOS 12.0+ devices
- Support for desktop platforms (Windows, macOS, Linux)
- Responsive design for different screen sizes

---

## 6. Appendices

### 6.1 Glossary
- **Annotation**: Digital markings added to PDF content
- **BPM**: Beats Per Minute, tempo measurement for metronome
- **Layer**: Organizational container for annotations
- **Piece**: Individual PDF sheet music document
- **Spot**: Practice-focused area marked on sheet music
- **Syncfusion**: Third-party PDF viewing library

### 6.2 Diagrams
- Use case diagrams (see repository documentation)
- Class diagrams (see CODE_EXPLANATION.md)
- Sequence diagrams (see developer documentation)

### 6.3 References
- Flutter Documentation: https://docs.flutter.dev
- Material Design Guidelines: https://material.io/design
- Syncfusion PDF Viewer: https://help.syncfusion.com/flutter/pdf-viewer
- Riverpod Documentation: https://riverpod.dev