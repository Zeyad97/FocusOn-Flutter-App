import 'package:flutter/material.dart';
import '../models/pdf_document.dart';
import '../services/storage_service.dart';
import '../widgets/pdf_list_item.dart';
import 'pdf_viewer_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final StorageService _storageService = StorageService();
  List<PDFDocument> _favoritePDFs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favorites = await _storageService.getFavoritePDFs();
      setState(() {
        _favoritePDFs = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading favorites: $e')),
        );
      }
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

  Future<void> _removeFavorite(PDFDocument pdf) async {
    final updatedPdf = pdf.copyWith(isFavorite: false);
    await _storageService.savePDF(updatedPdf);
    await _loadFavorites();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoritePDFs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No favorite sheet music yet\nMark PDFs as favorites to see them here',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _favoritePDFs.length,
                  itemBuilder: (context, index) {
                    final pdf = _favoritePDFs[index];
                    return PDFListItem(
                      pdf: pdf,
                      onTap: () => _openPDF(pdf),
                      onEdit: () {
                        // Navigate back to library for editing
                        final controller = DefaultTabController.of(context);
                        if (controller != null) {
                          controller.animateTo(0);
                        }
                      },
                      onDelete: () => _removeFavorite(pdf),
                    );
                  },
                ),
    );
  }
}
