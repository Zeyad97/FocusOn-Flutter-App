import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/piece.dart';
import '../models/spot.dart';

class PDFViewerScreen extends ConsumerStatefulWidget {
  final Piece piece;
  final bool isAnnotationMode;

  const PDFViewerScreen({
    Key? key,
    required this.piece,
    this.isAnnotationMode = false,
  }) : super(key: key);

  @override
  ConsumerState<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends ConsumerState<PDFViewerScreen> {
  late PdfViewerController _pdfViewerController;
  int currentPage = 1;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.piece.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel * 1.2).clamp(0.5, 3.0);
              });
              _pdfViewerController.zoomLevel = _zoomLevel;
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _zoomLevel = (_zoomLevel / 1.2).clamp(0.5, 3.0);
              });
              _pdfViewerController.zoomLevel = _zoomLevel;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: EdgeInsets.all(8.0),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Page $currentPage'),
                Text('Zoom: ${(_zoomLevel * 100).toInt()}%'),
              ],
            ),
          ),
          // PDF Viewer
          Expanded(
            child: SfPdfViewer.asset(
              widget.piece.pdfPath,
              controller: _pdfViewerController,
              onPageChanged: (PdfPageChangedDetails details) {
                setState(() {
                  currentPage = details.newPageNumber;
                });
              },
              onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                print('PDF loaded with ${details.document.pages.count} pages');
              },
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load PDF: ${details.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.isAnnotationMode
          ? FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Annotation mode not yet implemented')),
                );
              },
              child: Icon(Icons.edit),
              tooltip: 'Add Annotation',
            )
          : FloatingActionButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Spot creation not yet implemented')),
                );
              },
              child: Icon(Icons.add_location),
              tooltip: 'Add Practice Spot',
            ),
    );
  }
}

// Simple spot dialog for future implementation
class _EditSpotDialog extends StatefulWidget {
  final Piece piece;
  final int pageNumber;
  final Offset position;
  final Spot? spot;

  const _EditSpotDialog({
    Key? key,
    required this.piece,
    required this.pageNumber,
    required this.position,
    this.spot,
  }) : super(key: key);

  @override
  State<_EditSpotDialog> createState() => _EditSpotDialogState();
}

class _EditSpotDialogState extends State<_EditSpotDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.spot?.title ?? '');
    _descriptionController = TextEditingController(text: widget.spot?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.spot == null ? 'Create Practice Spot' : 'Edit Practice Spot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Text('Page: ${widget.pageNumber}'),
            Text('Position: (${widget.position.dx.toStringAsFixed(2)}, ${widget.position.dy.toStringAsFixed(2)})'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isNotEmpty) {
              Navigator.of(context).pop({
                'title': title,
                'description': _descriptionController.text.trim(),
                'page': widget.pageNumber,
                'position': widget.position,
              });
            }
          },
          child: Text(widget.spot == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}
