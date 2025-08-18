import 'package:flutter/material.dart';
import '../services/pdf_service.dart';
import '../models/pdf_document.dart';
import '../services/storage_service.dart';

class GoogleDriveImportDialog extends StatefulWidget {
  final Function(PDFDocument) onPDFImported;

  const GoogleDriveImportDialog({
    super.key,
    required this.onPDFImported,
  });

  @override
  State<GoogleDriveImportDialog> createState() => _GoogleDriveImportDialogState();
}

class _GoogleDriveImportDialogState extends State<GoogleDriveImportDialog> {
  final StorageService _storageService = StorageService();
  bool _isSignedIn = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _driveFiles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    setState(() => _isLoading = true);
    try {
      final isSignedIn = await PDFService.isSignedInToGoogleDrive();
      setState(() => _isSignedIn = isSignedIn);
      if (isSignedIn) {
        await _loadGoogleDriveFiles();
      }
    } catch (e) {
      setState(() => _error = 'Error checking sign-in status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInToGoogleDrive() async {
    setState(() => _isLoading = true);
    try {
      final success = await PDFService.signInToGoogleDrive();
      if (success) {
        setState(() => _isSignedIn = true);
        await _loadGoogleDriveFiles();
      } else {
        setState(() => _error = 'Failed to sign in to Google Drive');
      }
    } catch (e) {
      String errorMessage = 'Error signing in: $e';
      
      // Check for common Google Play Services errors
      if (e.toString().contains('SIGN_IN_REQUIRED') || 
          e.toString().contains('SERVICE_VERSION_UPDATE_REQUIRED') ||
          e.toString().contains('Google Play Services')) {
        errorMessage = 'Google Play Services issue detected.\n\n'
            'Please try these steps:\n'
            '1. Update Google Play Services in Play Store\n'
            '2. Restart the app\n'
            '3. If using emulator, ensure it has Google APIs';
      } else if (e.toString().contains('network') || e.toString().contains('internet')) {
        errorMessage = 'Network connection required.\n'
            'Please check your internet connection and try again.';
      }
      
      setState(() => _error = errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGoogleDriveFiles() async {
    setState(() => _isLoading = true);
    try {
      final files = await PDFService.getGoogleDrivePDFs();
      setState(() => _driveFiles = files);
    } catch (e) {
      setState(() => _error = 'Error loading files: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPDF(String fileId, String fileName) async {
    setState(() => _isLoading = true);
    try {
      final pdfDocument = await PDFService.downloadPDFFromGoogleDrive(fileId, fileName);
      if (pdfDocument != null) {
        await _storageService.savePDF(pdfDocument);
        widget.onPDFImported(pdfDocument);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _error = 'Failed to download PDF');
      }
    } catch (e) {
      setState(() => _error = 'Error downloading PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_download,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import from Google Drive',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null) const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              )
            else if (!_isSignedIn)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sign in to Google Drive',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access your PDF files stored in Google Drive',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _signInToGoogleDrive,
                        icon: const Icon(Icons.login),
                        label: const Text('Sign In'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_driveFiles.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text('No PDF files found in Google Drive'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _driveFiles.length,
                  itemBuilder: (context, index) {
                    final file = _driveFiles[index];
                    final fileName = file['name'] ?? 'Unknown';
                    final fileSize = file['size'] != null
                        ? '${(int.parse(file['size']) / (1024 * 1024)).toStringAsFixed(1)} MB'
                        : 'Unknown size';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red.shade400,
                        ),
                        title: Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(fileSize),
                        trailing: IconButton(
                          onPressed: () => _downloadPDF(file['id'], fileName),
                          icon: const Icon(Icons.download),
                          tooltip: 'Download PDF',
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
