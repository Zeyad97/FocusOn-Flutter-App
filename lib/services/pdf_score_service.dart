import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/annotation.dart';

/// Enhanced PDF service for ScoreRead Pro functionality
class PDFScoreService {
  static const String _pdfDirectory = 'pdfs';
  static const String _thumbnailDirectory = 'thumbnails';
  
  /// Import PDF and create new Piece with ScoreRead Pro features
  static Future<Piece?> importPDFAsPiece() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result?.files.single.path == null) return null;

      final sourceFile = File(result!.files.single.path!);
      final fileName = result.files.single.name;
      
      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final pdfDir = Directory(path.join(appDir.path, _pdfDirectory));
      await pdfDir.create(recursive: true);
      
      // Copy file to app directory
      final targetFile = File(path.join(pdfDir.path, uniqueFileName));
      await sourceFile.copy(targetFile.path);
      
      // Generate thumbnail
      final thumbnailPath = await _generateThumbnail(targetFile.path, timestamp.toString());
      
      // Extract metadata from filename
      final metadata = _extractMetadataFromFilename(fileName);
      
      // Create Piece with ScoreRead Pro features
      final piece = Piece(
        id: timestamp.toString(),
        title: metadata['title'] ?? _cleanFileName(fileName),
        composer: metadata['composer'] ?? '',
        pdfFilePath: targetFile.path,
        difficulty: metadata['difficulty'] ?? 3,
        keySignature: metadata['key'] ?? '',
        totalTimeSpent: Duration.zero,
        thumbnailPath: thumbnailPath,
        targetTempo: metadata['tempo']?.toDouble(),
        currentTempo: metadata['tempo']?.toDouble(),
        totalPages: await getPDFPageCount(targetFile.path) ?? 1,
        spots: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      return piece;
    } catch (e) {
      debugPrint('Error importing PDF: $e');
      return null;
    }
  }
  
  /// Generate thumbnail from PDF first page
  static Future<String?> _generateThumbnail(String pdfPath, String id) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final thumbnailDir = Directory(path.join(appDir.path, _thumbnailDirectory));
      await thumbnailDir.create(recursive: true);
      
      final thumbnailPath = path.join(thumbnailDir.path, '$id.png');
      
      // TODO: Implement actual PDF thumbnail generation
      // For now, return null (will use default icon)
      return null;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }
  
  /// Extract metadata from filename using common patterns
  static Map<String, dynamic> _extractMetadataFromFilename(String fileName) {
    final metadata = <String, dynamic>{};
    final cleanName = fileName.replaceAll('.pdf', '').toLowerCase();
    
    // Extract composer and title from patterns like "Bach - Invention No. 1"
    if (cleanName.contains(' - ')) {
      final parts = cleanName.split(' - ');
      metadata['composer'] = _capitalizeWords(parts[0].trim());
      metadata['title'] = _capitalizeWords(parts[1].trim());
    }
    
    // Extract key signature patterns
    final keyPatterns = [
      RegExp(r'\b([A-G][#b]?)\s*(major|minor|maj|min)\b', caseSensitive: false),
      RegExp(r'\bin\s+([A-G][#b]?)\s*(major|minor|maj|min)\b', caseSensitive: false),
    ];
    
    for (final pattern in keyPatterns) {
      final match = pattern.firstMatch(cleanName);
      if (match != null) {
        final key = match.group(1)!.toUpperCase();
        final mode = match.group(2)!.toLowerCase();
        metadata['key'] = '$key ${mode == 'maj' ? 'major' : mode == 'min' ? 'minor' : mode}';
        break;
      }
    }
    
    // Extract tempo from patterns like "120 BPM" or "Allegro"
    final tempoPattern = RegExp(r'(\d+)\s*bpm', caseSensitive: false);
    final tempoMatch = tempoPattern.firstMatch(cleanName);
    if (tempoMatch != null) {
      metadata['tempo'] = int.tryParse(tempoMatch.group(1)!);
    } else {
      // Common tempo markings
      final tempoMarkings = {
        'largo': 50,
        'adagio': 70,
        'andante': 90,
        'moderato': 110,
        'allegro': 130,
        'presto': 170,
      };
      
      for (final marking in tempoMarkings.keys) {
        if (cleanName.contains(marking)) {
          metadata['tempo'] = tempoMarkings[marking];
          break;
        }
      }
    }
    
    // Extract difficulty from patterns or composer
    if (cleanName.contains('beginner') || cleanName.contains('easy')) {
      metadata['difficulty'] = 1;
    } else if (cleanName.contains('intermediate')) {
      metadata['difficulty'] = 3;
    } else if (cleanName.contains('advanced') || cleanName.contains('virtuoso')) {
      metadata['difficulty'] = 5;
    } else {
      // Estimate difficulty by composer
      final composer = metadata['composer']?.toString().toLowerCase() ?? '';
      if (composer.contains('mozart') || composer.contains('haydn')) {
        metadata['difficulty'] = 3;
      } else if (composer.contains('chopin') || composer.contains('liszt')) {
        metadata['difficulty'] = 4;
      } else if (composer.contains('rachmaninoff') || composer.contains('prokofiev')) {
        metadata['difficulty'] = 5;
      }
    }
    
    return metadata;
  }
  
  /// Clean filename for display
  static String _cleanFileName(String fileName) {
    return fileName
        .replaceAll('.pdf', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => _capitalizeWords(word))
        .join(' ');
  }
  
  /// Capitalize words properly
  static String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Delete PDF file and associated data
  static Future<bool> deletePDF(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting PDF: $e');
      return false;
    }
  }
  
  /// Get PDF page count
  static Future<int?> getPDFPageCount(String filePath) async {
    try {
      // Try to get actual page count by reading PDF file
      final file = File(filePath);
      if (!await file.exists()) return null;
      
      // Read PDF content to extract page count
      final bytes = await file.readAsBytes();
      final content = String.fromCharCodes(bytes);
      
      // Look for PDF page count indicators
      // Method 1: Count /Type /Page entries
      final pagePattern = RegExp(r'/Type\s*/Page\b');
      final pageMatches = pagePattern.allMatches(content);
      int pageCount = pageMatches.length;
      
      // Method 2: Look for /Count entry in Pages object
      if (pageCount == 0) {
        final countPattern = RegExp(r'/Count\s+(\d+)');
        final countMatch = countPattern.firstMatch(content);
        if (countMatch != null) {
          pageCount = int.tryParse(countMatch.group(1) ?? '0') ?? 0;
        }
      }
      
      // Method 3: Look for PDF page references
      if (pageCount == 0) {
        final objPattern = RegExp(r'\d+\s+0\s+obj');
        final objMatches = objPattern.allMatches(content);
        // Rough estimate: typically 1-3 objects per page
        pageCount = (objMatches.length / 2).ceil();
      }
      
      // Ensure reasonable bounds
      if (pageCount <= 0) pageCount = 1;
      if (pageCount > 200) pageCount = 200; // Sanity check
      
      debugPrint('PDF page count detected: $pageCount pages for $filePath');
      return pageCount;
    } catch (e) {
      debugPrint('Error getting PDF page count: $e');
      // Return null to let Syncfusion handle it
      return null;
    }
  }
  
  /// Export annotations as PDF overlay
  static Future<bool> exportAnnotations(
    String pdfPath,
    List<Annotation> annotations,
    String outputPath,
  ) async {
    try {
      // TODO: Implement PDF annotation export
      return true;
    } catch (e) {
      debugPrint('Error exporting annotations: $e');
      return false;
    }
  }
  
  /// Extract text from PDF for search functionality
  static Future<String?> extractPDFText(String filePath) async {
    try {
      // TODO: Implement PDF text extraction
      return null;
    } catch (e) {
      debugPrint('Error extracting PDF text: $e');
      return null;
    }
  }
  
  /// Create backup of piece with annotations
  static Future<String?> createBackup(Piece piece, List<Annotation> annotations) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(path.join(appDir.path, 'backups'));
      await backupDir.create(recursive: true);
      
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = path.join(backupDir.path, '${piece.id}_$timestamp.json');
      
      // TODO: Implement backup serialization
      return backupPath;
    } catch (e) {
      debugPrint('Error creating backup: $e');
      return null;
    }
  }
}

/// View modes for PDF display
enum ViewMode {
  singlePage('Single Page'),
  twoPage('Two Page'),
  verticalScroll('Vertical Scroll'),
  horizontalScroll('Horizontal Scroll'),
  grid('Grid View');

  const ViewMode(this.displayName);
  final String displayName;
  
  /// Get icon for view mode
  IconData get icon {
    switch (this) {
      case ViewMode.singlePage:
        return Icons.looks_one;
      case ViewMode.twoPage:
        return Icons.looks_two;
      case ViewMode.verticalScroll:
        return Icons.view_agenda;
      case ViewMode.horizontalScroll:
        return Icons.view_carousel;
      case ViewMode.grid:
        return Icons.grid_view;
    }
  }
  
  /// Check if mode supports page turning
  bool get supportsPageTurn {
    switch (this) {
      case ViewMode.singlePage:
      case ViewMode.twoPage:
        return true;
      case ViewMode.verticalScroll:
      case ViewMode.horizontalScroll:
      case ViewMode.grid:
        return false;
    }
  }
}
