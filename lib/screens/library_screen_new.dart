import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../models/pdf_document.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../providers/unified_library_provider.dart';
import '../providers/practice_provider.dart';
import '../services/spot_service.dart';
import 'pdf_viewer_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Recently Added';

  @override
  Widget build(BuildContext context) {
    final piecesAsync = ref.watch(unifiedLibraryProvider);
    
    return piecesAsync.when(
      data: (pieces) => _buildLibraryContent(pieces),
      loading: () => Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Error loading library: $error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(unifiedLibraryProvider),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryContent(List<Piece> pieces) {
    final filteredPieces = _getFilteredPieces(pieces);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar with Glass Effect
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryPurple,
                      AppColors.accentPurple,
                    ],
                  ),
                ),
                child: FlexibleSpaceBar(
                  title: const Text(
                    'Music Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  background: Stack(
                    children: [
                      // Animated background elements
                      Positioned(
                        right: -60,
                        top: -60,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Music notes decoration
                      Positioned(
                        right: 24,
                        top: 80,
                        child: Icon(
                          Icons.music_note,
                          color: Colors.white.withOpacity(0.15),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    _buildQuickStats(pieces),
                    
                    const SizedBox(height: 20),

                    // Search Bar
                    _buildSearchBar(),
                    
                    const SizedBox(height: 16),

                    // Filter and Sort Row
                    Row(
                      children: [
                        Expanded(child: _buildCategoryFilter()),
                        const SizedBox(width: 12),
                        _buildSortDropdown(),
                      ],
                    ),
                    
                    const SizedBox(height: 20),

                    // Pieces Grid
                    if (filteredPieces.isEmpty)
                      _buildEmptyState()
                    else
                      _buildPiecesGrid(filteredPieces),
                    
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple,
              AppColors.accentPurple,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _importPDF,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 24),
          label: const Text(
            'Import PDF',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  List<Piece> _getFilteredPieces(List<Piece> pieces) {
    var filtered = pieces;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((piece) => 
        piece.tags.contains(_selectedCategory) ||
        (piece.tags.contains('Classical') && _selectedCategory == 'Classical') ||
        (piece.tags.contains('Jazz') && _selectedCategory == 'Jazz') ||
        (piece.tags.contains('Pop') && _selectedCategory == 'Pop') ||
        (piece.tags.contains('Bossa Nova') && _selectedCategory == 'Bossa Nova')
      ).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((piece) =>
          piece.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          piece.composer.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Composer':
        filtered.sort((a, b) => a.composer.compareTo(b.composer));
        break;
      case 'Progress':
        filtered.sort((a, b) => b.readinessPercentage.compareTo(a.readinessPercentage));
        break;
      case 'Recently Added':
      default:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    return filtered;
  }

  Widget _buildQuickStats(List<Piece> pieces) {
    final totalPieces = pieces.length;
    final avgProgress = pieces.isEmpty ? 0.0 : 
      pieces.map((p) => p.readinessPercentage).reduce((a, b) => a + b) / pieces.length;
    final totalSpots = pieces.fold<int>(0, (sum, piece) => sum + piece.spots.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '$totalPieces',
                  'Pieces',
                  Icons.library_music_outlined,
                  AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '$totalSpots',
                  'Practice Spots',
                  Icons.place_outlined,
                  AppColors.spotRed,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '${avgProgress.toInt()}%',
                  'Avg Progress',
                  Icons.trending_up_outlined,
                  AppColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search pieces or composers...',
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Classical', 'Jazz', 'Pop', 'Bossa Nova'];
    
    return Container(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: EdgeInsets.only(right: index < categories.length - 1 ? 8 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppColors.primaryPurple,
                checkmarkColor: Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sort_outlined,
            color: AppColors.textSecondary,
            size: 18,
          ),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: _sortBy,
            underline: Container(),
            isDense: true,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            items: ['Recently Added', 'Title', 'Composer', 'Progress']
                .map((sort) => DropdownMenuItem(
                      value: sort,
                      child: Text(sort),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPiecesGrid(List<Piece> pieces) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        final piece = pieces[index];
        return _buildPieceCard(piece);
      },
    );
  }

  Widget _buildPieceCard(Piece piece) {
    final categoryColor = _getCategoryColor(piece.tags.isNotEmpty ? piece.tags.first : 'Unknown');
    final difficultyText = _getDifficultyText(piece.difficulty);
    
    return GestureDetector(
      onTap: () => _openPiece(piece),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderLight.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      categoryColor.withOpacity(0.8),
                      categoryColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const Spacer(),
                      if (piece.spots.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${piece.spots.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        piece.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Composer
                      Text(
                        piece.composer,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const Spacer(),

                      // Progress and tags row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: categoryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        piece.tags.isNotEmpty ? piece.tags.first : 'Music',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: categoryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                
                                // Progress bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 4,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                          color: categoryColor.withOpacity(0.2),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: piece.readinessPercentage / 100.0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(2),
                                              color: categoryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${piece.readinessPercentage.toInt()}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: categoryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'classical':
        return AppColors.primaryPurple;
      case 'jazz':
        return AppColors.warningOrange;
      case 'pop':
        return AppColors.errorRed;
      case 'bossa nova':
        return AppColors.successGreen;
      default:
        return AppColors.primaryPurple;
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.library_music_outlined,
              size: 60,
              color: AppColors.primaryPurple.withOpacity(0.6),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'No music pieces yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Import your first PDF to start your\nmusical journey with AI-powered practice',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple,
                  AppColors.accentPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _importPDF,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.upload_file_outlined, size: 20),
              label: const Text(
                'Import Your First Piece',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _openPiece(Piece piece) {
    // Update last opened time
    ref.read(unifiedLibraryProvider.notifier).updateLastOpened(piece.id);
    
    // Navigate to PDF viewer with the piece
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerScreen(
          document: PDFDocument(
            id: piece.id,
            title: piece.title,
            filePath: piece.pdfFilePath,
            category: piece.tags.isNotEmpty ? piece.tags.first : 'Music',
            isFavorite: false,
            lastOpened: DateTime.now(),
          ),
        ),
      ),
    ).then((_) {
      // Refresh library when returning from PDF viewer
      ref.refresh(unifiedLibraryProvider);
    });
  }

  void _startPractice(MusicPiece piece) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${piece.title} for practice'),
        backgroundColor: piece.categoryColor,
      ),
    );
  }

  void _importPDF() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.library_music, color: AppColors.successGreen),
            const SizedBox(width: 8),
            const Text('Add Music'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how you\'d like to add your music:'),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.folder, color: AppColors.primaryPurple),
              title: const Text('From Device'),
              subtitle: const Text('Select PDF from your device'),
              onTap: () {
                Navigator.pop(context);
                _importFromDevice();
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: AppColors.accentPurple),
              title: const Text('Create Manually'),
              subtitle: const Text('Add piece details without PDF'),
              onTap: () {
                Navigator.pop(context);
                _createManualPiece();
              },
            ),
            ListTile(
              leading: Icon(Icons.science, color: AppColors.warningOrange),
              title: const Text('Create Demo Piece'),
              subtitle: const Text('Add a sample piece for testing'),
              onTap: () {
                Navigator.pop(context);
                _createDemoPiece();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _createDemoPiece() async {
    final now = DateTime.now();
    final demoPiece = Piece(
      id: 'demo_${now.millisecondsSinceEpoch}',
      title: 'My Practice Piece',
      composer: 'Practice Composer',
      keySignature: 'C major',
      difficulty: 3,
      tags: ['Practice', 'Classical'],
      pdfFilePath: 'assets/pdfs/demo.pdf',
      spots: [],
      createdAt: now,
      updatedAt: now,
      totalPages: 4,
    );
    
    await ref.read(unifiedLibraryProvider.notifier).addPiece(demoPiece);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demo piece "${demoPiece.title}" created! Tap it to add practice spots.'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _createManualPiece() async {
    final pieceDetails = await _showPieceDetailsDialog();
    if (pieceDetails == null) return;

    final now = DateTime.now();
    final manualPiece = Piece(
      id: 'manual_${now.millisecondsSinceEpoch}',
      title: pieceDetails['title'],
      composer: pieceDetails['composer'] ?? 'Unknown Composer',
      keySignature: pieceDetails['keySignature'],
      difficulty: pieceDetails['difficulty'],
      tags: ['Manual'],
      pdfFilePath: '', // No PDF file for manual pieces
      spots: [],
      createdAt: now,
      updatedAt: now,
      totalPages: 0,
    );
    
    await ref.read(unifiedLibraryProvider.notifier).addPiece(manualPiece);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Piece "${manualPiece.title}" created! Tap it to add practice spots.'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<Map<String, dynamic>?> _showPieceDetailsDialog() async {
    final titleController = TextEditingController();
    final composerController = TextEditingController();
    final keyController = TextEditingController();
    int difficulty = 3;
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add Piece Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g., Chopin Nocturne Op. 9 No. 2',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: composerController,
                  decoration: InputDecoration(
                    labelText: 'Composer',
                    hintText: 'e.g., Frédéric Chopin',
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: keyController,
                  decoration: InputDecoration(
                    labelText: 'Key Signature',
                    hintText: 'e.g., E♭ major',
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Text('Difficulty: '),
                    Expanded(
                      child: Slider(
                        value: difficulty.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$difficulty ${_getDifficultyLabel(difficulty)}',
                        onChanged: (value) {
                          setState(() {
                            difficulty = value.round();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(context, {
                    'title': titleController.text.trim(),
                    'composer': composerController.text.trim().isEmpty 
                        ? null : composerController.text.trim(),
                    'keySignature': keyController.text.trim().isEmpty 
                        ? null : keyController.text.trim(),
                    'difficulty': difficulty,
                    'tags': ['Imported'],
                  });
                }
              },
              child: Text('Add Piece'),
            ),
          ],
        ),
      ),
    );
  }

  String _getDifficultyLabel(int difficulty) {
    switch (difficulty) {
      case 1: return '(Beginner)';
      case 2: return '(Easy)';
      case 3: return '(Intermediate)';
      case 4: return '(Advanced)';
      case 5: return '(Expert)';
      default: return '';
    }
  }

  Future<void> _importFromDevice() async {
    try {
      print('LibraryScreen: Starting PDF import from device');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening device file picker...'),
          backgroundColor: AppColors.primaryPurple,
        ),
      );

      // Import PDF file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('LibraryScreen: PDF file selected: ${file.name}, path: ${file.path}');
        
        if (file.path != null) {
          // Show dialog to get piece details
          final pieceDetails = await _showPieceDetailsDialog();
          
          if (pieceDetails != null) {
            final now = DateTime.now();
            final piece = Piece(
              id: 'imported_${now.millisecondsSinceEpoch}',
              title: pieceDetails['title'] ?? file.name.replaceAll('.pdf', ''),
              composer: pieceDetails['composer'] ?? 'Unknown Composer',
              keySignature: pieceDetails['keySignature'],
              difficulty: pieceDetails['difficulty'] ?? 3,
              tags: pieceDetails['tags'] ?? ['Imported'],
              pdfFilePath: file.path!,
              spots: [],
              createdAt: now,
              updatedAt: now,
              totalPages: 1, // Will be updated when PDF is opened
            );
            
            print('LibraryScreen: Created piece object with ID: ${piece.id}, title: ${piece.title}');
            print('LibraryScreen: Calling addPiece...');
            
            await ref.read(unifiedLibraryProvider.notifier).addPiece(piece);
            
            print('LibraryScreen: addPiece completed successfully');
            
            // CRITICAL FIX: Create an immediate practice spot for the imported piece
            // This ensures the imported PDF appears in the AI practice dashboard
            await _createInitialPracticeSpot(piece);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Imported "${piece.title}" successfully! Check the AI Practice Dashboard to start practicing.'),
                  backgroundColor: AppColors.successGreen,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } else {
            print('LibraryScreen: User cancelled piece details dialog');
          }
        } else {
          print('LibraryScreen: File path is null');
        }
      } else {
        print('LibraryScreen: No file selected or result is null');
      }
    } catch (e) {
      print('LibraryScreen: Error importing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing PDF: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  /// Create an initial practice spot for imported pieces to ensure they appear in AI dashboard
  Future<void> _createInitialPracticeSpot(Piece piece) async {
    try {
      print('LibraryScreen: Creating initial practice spot for imported piece ${piece.id}');
      
      final now = DateTime.now();
      final spot = Spot(
        id: 'initial_${piece.id}_${now.millisecondsSinceEpoch}',
        pieceId: piece.id,
        title: 'Overall Practice - ${piece.title}',
        description: 'General practice for this imported piece. Open the PDF to create specific spots.',
        pageNumber: 1,
        x: 0.1, // Left side
        y: 0.1, // Top
        width: 0.8, // Most of the width
        height: 0.2, // Small height
        priority: SpotPriority.medium,
        readinessLevel: ReadinessLevel.newSpot,
        color: SpotColor.green,
        createdAt: now,
        updatedAt: now,
        nextDue: null, // Makes it immediately due for practice
        isActive: true,
      );
      
      // Import SpotService to save the spot
      final spotService = ref.read(spotServiceProvider);
      await spotService.saveSpot(spot);
      
      print('LibraryScreen: Initial practice spot created successfully');
      
      // Refresh the practice dashboard
      ref.read(practiceProvider.notifier).refresh();
      
    } catch (e) {
      print('LibraryScreen: Error creating initial practice spot: $e');
    }
  }

  void _importFromCloud() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to Google Drive...'),
        backgroundColor: AppColors.warningOrange,
      ),
    );
  }
}
