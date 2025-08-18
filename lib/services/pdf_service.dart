import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/pdf_document.dart';

class PDFService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.readonly',
    ],
  );
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<Directory> get _localDirectory async {
    final path = await _localPath;
    final directory = Directory('$path/pdfs');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API level 33+), we don't need storage permission for file picker
      // The file picker uses the system picker which has its own permissions
      return true;
    }
    return true; // iOS doesn't need explicit storage permission for app documents
  }

  static Future<PDFDocument?> pickAndImportPDF() async {
    try {
      // Request permission first
      final hasPermission = await requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied');
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        
        // Copy to app directory
        final localDir = await _localDirectory;
        final localFile = File('${localDir.path}/$fileName');
        await file.copy(localFile.path);

        // Create PDF document model
        final pdfDocument = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName.replaceAll('.pdf', ''),
          filePath: localFile.path,
          category: 'Other',
        );

        return pdfDocument;
      }
    } catch (e) {
      print('Error picking PDF: $e');
    }
    return null;
  }

  // Google Drive Integration
  static Future<bool> signInToGoogleDrive() async {
    try {
      // Check if Google Play Services is available
      final account = await _googleSignIn.signIn();
      return account != null;
    } on Exception catch (e) {
      print('Google Sign In Exception: $e');
      
      // Re-throw with more specific error information
      if (e.toString().contains('SIGN_IN_REQUIRED') || 
          e.toString().contains('SERVICE_VERSION_UPDATE_REQUIRED')) {
        throw Exception('Google Play Services needs to be updated or is not available');
      } else if (e.toString().contains('NETWORK_ERROR')) {
        throw Exception('Network connection required for Google Drive access');
      } else {
        throw Exception('Google Sign In failed: ${e.toString()}');
      }
    } catch (e) {
      print('Error signing in to Google Drive: $e');
      throw Exception('Unable to connect to Google Drive: $e');
    }
  }

  static Future<void> signOutFromGoogleDrive() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google Drive: $e');
    }
  }

  static Future<bool> isSignedInToGoogleDrive() async {
    return _googleSignIn.isSignedIn();
  }

  static Future<List<Map<String, dynamic>>> getGoogleDrivePDFs() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        throw Exception('Not signed in to Google Drive');
      }

      final authHeaders = await account.authHeaders;
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files?q=mimeType=\'application/pdf\'&fields=files(id,name,size,modifiedTime)',
        ),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['files'] ?? []);
      } else {
        throw Exception('Failed to fetch Google Drive files');
      }
    } catch (e) {
      print('Error fetching Google Drive PDFs: $e');
      return [];
    }
  }

  static Future<PDFDocument?> downloadPDFFromGoogleDrive(
    String fileId,
    String fileName,
  ) async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) {
        throw Exception('Not signed in to Google Drive');
      }

      final authHeaders = await account.authHeaders;
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
        ),
        headers: authHeaders,
      );

      if (response.statusCode == 200) {
        // Save to local directory
        final localDir = await _localDirectory;
        final localFile = File('${localDir.path}/$fileName');
        await localFile.writeAsBytes(response.bodyBytes);

        // Create PDF document model
        final pdfDocument = PDFDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: fileName.replaceAll('.pdf', ''),
          filePath: localFile.path,
          category: 'Other',
        );

        return pdfDocument;
      } else {
        throw Exception('Failed to download PDF from Google Drive');
      }
    } catch (e) {
      print('Error downloading PDF from Google Drive: $e');
      return null;
    }
  }

  static Future<bool> deletePDFFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Error deleting PDF file: $e');
    }
    return false;
  }

  static Future<bool> doesPDFExist(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static Future<int> getPDFFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting PDF file size: $e');
    }
    return 0;
  }
}
