import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pdf_document.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_list_item.dart';
import '../widgets/google_drive_import_dialog.dart';
import '../providers/user_provider.dart';
import 'pdf_viewer_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final StorageService _storageService = StorageService();
  List<PDFDocument> _pdfs = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('Starting _loadData...');
    setState(() {
      _isLoading = true;
    });

    try {
      print('About to load PDFs...');
      // Simplified loading with immediate fallback
      List<PDFDocument> pdfs = [];
      List<String> categories = ['Classical', 'Jazz', 'Pop', 'Folk', 'Other'];
      
      try {
        pdfs = await _storageService.getAllPDFs().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('PDF loading timed out, using empty list');
            return <PDFDocument>[];
          },
        );
        print('Successfully loaded ${pdfs.length} PDFs');
      } catch (e) {
        print('Error loading PDFs: $e');
        pdfs = [];
      }
      
      try {
        categories = await _storageService.getCategories().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            print('Categories loading timed out, using defaults');
            return ['Classical', 'Jazz', 'Pop', 'Folk', 'Other'];
          },
        );
        print('Successfully loaded ${categories.length} categories');
      } catch (e) {
        print('Error loading categories: $e');
        categories = ['Classical', 'Jazz', 'Pop', 'Folk', 'Other'];
      }
      
      print('Setting state with data...');
      setState(() {
        _pdfs = pdfs;
        _categories = ['All', ...categories];
        _isLoading = false;
      });
      print('_loadData completed successfully');
    } catch (e) {
      print('Major error in _loadData: $e');
      setState(() {
        _pdfs = [];
        _categories = ['All', 'Classical', 'Jazz', 'Pop', 'Folk', 'Other'];
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading library: $e')),
        );
      }
    }
  }

  List<PDFDocument> get _filteredPDFs {
    if (_selectedCategory == 'All') {
      return _pdfs;
    }
    return _pdfs.where((pdf) => pdf.category == _selectedCategory).toList();
  }

  Future<void> _addPDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pdfDocument = await PDFService.pickAndImportPDF();
      if (pdfDocument != null) {
        await _storageService.savePDF(pdfDocument);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF added to library')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding PDF: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import from Device'),
              subtitle: const Text('Select PDF files from your device'),
              onTap: () {
                Navigator.pop(context);
                _addPDF();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Import from Google Drive'),
              subtitle: const Text('Access your cloud-stored PDFs'),
              onTap: () {
                Navigator.pop(context);
                _showGoogleDriveDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGoogleDriveDialog() {
    showDialog(
      context: context,
      builder: (context) => GoogleDriveImportDialog(
        onPDFImported: (pdf) async {
          await _loadData();
        },
      ),
    );
  }

  Future<void> _deletePDF(PDFDocument pdf) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete PDF'),
        content: Text('Are you sure you want to delete "${pdf.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deletePDF(pdf.id);
      await PDFService.deletePDFFile(pdf.filePath);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF deleted')),
        );
      }
    }
  }

  Future<void> _editPDF(PDFDocument pdf) async {
    final result = await showDialog<PDFDocument>(
      context: context,
      builder: (context) => _EditPDFDialog(pdf: pdf, categories: _categories.where((c) => c != 'All').toList()),
    );

    if (result != null) {
      await _storageService.savePDF(result);
      await _loadData();
    }
  }

  void _openPDF(PDFDocument pdf) async {
    final updatedPdf = pdf.copyWith(lastOpened: DateTime.now());
    await _storageService.savePDF(updatedPdf);
    
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerScreen(document: pdf),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${userProvider.userName}! 👋',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Music Library',
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: _showImportOptions,
                icon: const Icon(Icons.cloud_download),
                tooltip: 'Import from Google Drive',
              ),
              FilledButton.icon(
                onPressed: _isLoading ? null : _addPDF,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add PDF'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 16),
            ],
            floating: true,
            pinned: true,
          ),
          // Category filter section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Categories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content area
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your music library...'),
                  ],
                ),
              ),
            )
          else if (_filteredPDFs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_music_outlined,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _selectedCategory == 'All' 
                          ? 'No sheet music yet'
                          : 'No sheets in $_selectedCategory',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory == 'All'
                          ? 'Add your first PDF to get started'
                          : 'Try selecting a different category',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    if (_selectedCategory == 'All') ...[
                      const SizedBox(height: 32),
                      FilledButton.icon(
                        onPressed: _addPDF,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Sheet Music'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pdf = _filteredPDFs[index];
                    return PDFListItem(
                      pdf: pdf,
                      onTap: () => _openPDF(pdf),
                      onEdit: () => _editPDF(pdf),
                      onDelete: () => _deletePDF(pdf),
                    );
                  },
                  childCount: _filteredPDFs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditPDFDialog extends StatefulWidget {
  final PDFDocument pdf;
  final List<String> categories;

  const _EditPDFDialog({required this.pdf, required this.categories});

  @override
  State<_EditPDFDialog> createState() => _EditPDFDialogState();
}

class _EditPDFDialogState extends State<_EditPDFDialog> {
  late TextEditingController _titleController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.pdf.title);
    _selectedCategory = widget.pdf.category;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit PDF'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: widget.categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final updatedPdf = widget.pdf.copyWith(
              title: _titleController.text.trim(),
              category: _selectedCategory,
            );
            Navigator.pop(context, updatedPdf);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
