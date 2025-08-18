# Practice Spots Database Integration Guide

## Overview

This implementation provides a clean, modular SQLite database system for storing and managing practice spots that users mark on PDF music sheets. The system is designed to be:

- ✅ **Simple to use** - Clean API matching your exact requirements
- ✅ **Extensible** - Ready for future cloud sync and advanced features  
- ✅ **Performant** - Optimized with proper indexing
- ✅ **Offline-first** - Works completely offline, no login required

## Quick Start

### 1. Core Components

```dart
// Database layer
import 'package:music_app/database/db_helper.dart';

// Models  
import 'package:music_app/models/practice_spot.dart';

// Service layer
import 'package:music_app/services/spot_manager.dart';

// UI integration
import 'package:music_app/widgets/pdf_with_spots_viewer.dart';
```

### 2. Basic Usage

#### Creating a Practice Spot
```dart
// When user marks a spot on the PDF
final spotId = await SpotManager.createSpot(
  pieceName: "Chopin Nocturne Op. 9 No. 2",
  pageNumber: 1,
  x: 0.3,        // Relative position (0.0 to 1.0)
  y: 0.2,        // Relative position (0.0 to 1.0) 
  width: 0.15,   // Relative width (0.0 to 1.0)
  height: 0.08,  // Relative height (0.0 to 1.0)
  color: "red",  // "red", "yellow", or "green"
  title: "Difficult trill passage",
  priority: "high",
);
```

#### Loading Spots for a PDF
```dart
// Get all spots for a piece
final spots = await SpotManager.getSpotsForPiece("Chopin Nocturne Op. 9 No. 2");

// Get spots for specific page only
final pageSpots = await SpotManager.getSpotsForPage("Chopin Nocturne Op. 9 No. 2", 1);
```

#### Recording Practice
```dart
// When user practices a spot
await SpotManager.recordPractice(
  spotId: spotId,
  durationMinutes: 10,
  qualityScore: 4, // 1-5 rating (optional)
  notes: "Much better today, tempo more consistent",
);
```

### 3. Integration with Riverpod State Management

```dart
class MyPdfViewer extends ConsumerWidget {
  final String pieceName;
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch spots for this piece - automatically updates UI
    final spotsAsync = ref.watch(spotsForPieceProvider(pieceName));
    
    return spotsAsync.when(
      data: (spots) => _buildPdfWithSpots(spots),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### 4. Database Schema

The database automatically creates these tables:

#### `spots` table (your exact requirements + extensions):
```sql
CREATE TABLE spots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Auto-increment primary key
  piece TEXT NOT NULL,                   -- Name of music piece
  page INTEGER NOT NULL,                 -- Page number in PDF
  x REAL NOT NULL,                       -- X coordinate (0.0-1.0)
  y REAL NOT NULL,                       -- Y coordinate (0.0-1.0) 
  width REAL NOT NULL,                   -- Width (0.0-1.0)
  height REAL NOT NULL,                  -- Height (0.0-1.0)
  color TEXT NOT NULL,                   -- Color: red/yellow/green
  last_practice TEXT,                    -- Last practice date/time
  repeat_count INTEGER DEFAULT 0,        -- Practice count
  readiness INTEGER DEFAULT 0,           -- Readiness score (0-100)
  
  -- Extended fields for better functionality
  title TEXT,                            -- Optional spot title
  description TEXT,                      -- Optional description
  notes TEXT,                            -- User notes
  priority TEXT DEFAULT 'medium',        -- Priority: low/medium/high
  created_at TEXT NOT NULL,              -- Creation timestamp
  updated_at TEXT NOT NULL,              -- Last update timestamp
  is_active INTEGER DEFAULT 1,           -- Soft delete flag
  
  -- Future cloud sync support
  sync_status TEXT DEFAULT 'local',      -- Sync status
  cloud_id TEXT                          -- Cloud database ID
);
```

#### `practice_history` table (for detailed tracking):
```sql
CREATE TABLE practice_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  spot_id INTEGER NOT NULL,              -- References spots.id
  practice_date TEXT NOT NULL,           -- When practiced
  duration_minutes INTEGER NOT NULL,     -- How long practiced
  quality_score INTEGER,                 -- 1-5 rating
  notes TEXT,                            -- Session notes
  
  FOREIGN KEY (spot_id) REFERENCES spots (id) ON DELETE CASCADE
);
```

## Integration Points

### 1. PDF Viewer Integration

Replace your current PDF viewer with the enhanced version:

```dart
// In your existing PDF screen
PdfWithSpotsViewer(
  pieceName: currentPiece.name,
  pdfPath: currentPiece.filePath,
  currentPage: currentPageNumber,
)
```

### 2. Practice Dashboard Integration

```dart
// Get spots due for practice
final dueSpots = await SpotManager.getDueSpots();

// Get practice statistics
final stats = await SpotManager.getStatistics();
// Returns: {totalSpots: 15, totalPractices: 42, totalPieces: 3, dueForPractice: 5}
```

### 3. Search and Filtering

```dart
// Search spots by text
final foundSpots = await SpotManager.searchSpots("difficult");

// Filter by priority
final urgentSpots = await SpotManager.getSpotsByPriority("high");

// Filter by color  
final redSpots = await SpotManager.getSpotsByColor("red");
```

## Advanced Features

### Spaced Repetition System (SRS)
The system automatically calculates when spots should be practiced again based on:
- Practice quality scores
- Current readiness level
- Historical performance

### Smart Readiness Calculation
- Quality 5 (Excellent): +20% readiness
- Quality 4 (Good): +10% readiness  
- Quality 3 (OK): +5% readiness
- Quality 2 (Struggled): -5% readiness
- Quality 1 (Failed): -10% readiness

### Next Practice Scheduling
- Readiness < 30%: Practice tomorrow
- Readiness 30-60%: Practice in 3 days
- Readiness 60-90%: Practice in 1 week  
- Readiness > 90%: Practice in 2 weeks

## Future Cloud Sync Support

The database is designed for easy cloud integration:

```dart
// Get spots that need syncing
final unsyncedSpots = await SpotManager.getSpotsNeedingSync();

// Mark as synced after cloud upload
await SpotManager.markAsSynced(spotIds, cloudIds);
```

## Migration from Existing System

If you have existing spots in the current complex system, you can migrate them:

```dart
// Example migration function
Future<void> migrateExistingSpots() async {
  final existingSpots = await oldSpotService.getAllActiveSpots();
  
  for (final oldSpot in existingSpots) {
    await SpotManager.createSpot(
      pieceName: oldSpot.pieceId, // Map to piece name
      pageNumber: oldSpot.pageNumber,
      x: oldSpot.x,
      y: oldSpot.y, 
      width: oldSpot.width,
      height: oldSpot.height,
      color: oldSpot.color.name,
      title: oldSpot.title,
      priority: oldSpot.priority.name,
    );
  }
}
```

## Performance Considerations

- Database has proper indexes for fast queries
- Relative coordinates (0.0-1.0) work on any screen size
- Lazy loading with Riverpod providers
- Soft deletes preserve data integrity
- Efficient queries optimized for common use cases

## Testing

```dart
// Clear all data (for testing)
await DBHelper.clearAllData();

// Get database statistics
final stats = await SpotManager.getStatistics();
print('Total spots: ${stats['totalSpots']}');
```

This implementation gives you exactly what you requested while being ready for future enhancements like cloud sync, advanced SRS algorithms, and team collaboration features.
