import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  
  // Use FFI database factory
  databaseFactory = databaseFactoryFfi;
  
  try {
    // Get the documents directory path
    final documentsPath = 'C:\\Users\\%USERNAME%\\Documents'; // Windows path
    final piecesDbPath = join(documentsPath, 'pieces.db');
    final spotsDbPath = join(documentsPath, 'spots.db');
    
    print('Checking pieces database...');
    if (await File(piecesDbPath).exists()) {
      final piecesDb = await openDatabase(piecesDbPath);
      final pieces = await piecesDb.query('pieces');
      print('Found ${pieces.length} pieces:');
      for (final piece in pieces) {
        print('  - ${piece['title']} (ID: ${piece['id']})');
      }
      await piecesDb.close();
    } else {
      print('Pieces database not found at: $piecesDbPath');
    }
    
    print('\nChecking spots database...');
    if (await File(spotsDbPath).exists()) {
      final spotsDb = await openDatabase(spotsDbPath);
      final spots = await spotsDb.query('spots');
      print('Found ${spots.length} spots:');
      for (final spot in spots) {
        print('  - ${spot['title']} (PieceID: ${spot['pieceId']}, Due: ${spot['nextDue']})');
      }
      await spotsDb.close();
    } else {
      print('Spots database not found at: $spotsDbPath');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
