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
import '../utils/feedback_system.dart';
import '../widgets/enhanced_search.dart';
import 'pdf_viewer/pdf_score_viewer.dart';
import 'settings/settings_screen.dart';

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
        piece.category?.toLowerCase() == _selectedCategory.toLowerCase() ||
        (piece.genre?.toLowerCase() == _selectedCategory.toLowerCase()) ||
        // Fallback for classical pieces
        (_selectedCategory == 'Classical' && (piece.category == null || piece.category!.isEmpty))
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
    return GestureDetector(
      onTap: () async {
        final result = await showSearch(
          context: context,
          delegate: EnhancedSearchDelegate(ref: ref),
        );
        
        if (result != null) {
          // Navigate to selected piece
          _openPiece(result);
        }
      },
      child: Container(
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
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search pieces, spots, bookmarks...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.filter_list, color: AppColors.textSecondary),
            ],
          ),
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
  final categoryColor = _getCategoryColor('Unknown');
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
                                        'Music',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: categoryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Difficulty indicator
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(piece.difficulty),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${piece.difficulty}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 8,
                                          ),
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

  /// Get color based on piece difficulty level (1-5) with colorblind support
  Color _getDifficultyColor(int difficulty) {
    final colorblindMode = ref.watch(colorblindModeProvider);
    
    if (colorblindMode) {
      // Use colorblind-friendly color scheme
      switch (difficulty) {
        case 1:
          return AppColors.colorblindBlue; // Beginner - Blue
        case 2:
          return AppColors.colorblindPattern1; // Easy - Sea Green
        case 3:
          return AppColors.colorblindPattern3; // Intermediate - Indigo  
        case 4:
          return AppColors.colorblindOrange; // Advanced - Orange
        case 5:
          return AppColors.colorblindRed; // Expert - Dark Red
        default:
          return AppColors.colorblindPattern3; // Default to indigo
      }
    } else {
      // Use standard color scheme
      switch (difficulty) {
        case 1:
          return AppColors.successGreen; // Beginner - Green
        case 2:
          return AppColors.lightPurple; // Easy - Light Purple
        case 3:
          return AppColors.accentPurple; // Intermediate - Medium Purple  
        case 4:
          return AppColors.warningOrange; // Advanced - Orange
        case 5:
          return AppColors.errorRed; // Expert - Red
        default:
          return AppColors.accentPurple; // Default to intermediate
      }
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
    try {
      print('LibraryScreen: Opening piece ${piece.title} with path: ${piece.pdfFilePath}');
      
      // Check if file exists
      if (piece.pdfFilePath.isEmpty) {
        throw Exception('PDF file path is empty');
      }
      
      // Update last opened time
      ref.read(unifiedLibraryProvider.notifier).updateLastOpened(piece.id);
      
      // Navigate to PDF viewer with the piece
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFScoreViewer(piece: piece),
        ),
      ).then((_) {
        // Refresh library when returning from PDF viewer
        ref.refresh(unifiedLibraryProvider);
      }).catchError((error) {
        print('LibraryScreen: Error navigating to PDF viewer: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening PDF: ${error.toString()}'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      });
    } catch (e) {
      print('LibraryScreen: Error opening piece: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening piece: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
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
            
            // Don't auto-create practice spots - let users create them manually
            
            if (mounted) {
              // Show enhanced success feedback
              FeedbackSystem.showSuccess(
                context,
                'Imported "${piece.title}" successfully!',
                duration: Duration(seconds: 3),
              );
              
              // Then show detailed popup like Lovable
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppColors.successGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Piece Imported Successfully!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Title:', piece.title),
                      _buildInfoRow('Composer:', piece.composer),
                      _buildInfoRow('Difficulty:', '${piece.difficulty}/5 stars'),
                      if (piece.keySignature != null && piece.keySignature!.isNotEmpty)
                        _buildInfoRow('Key:', piece.keySignature!),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primaryPurple,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Your piece is now in your library! You can open it to add practice spots and start practicing.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openPiece(piece);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Open Piece'),
                    ),
                  ],
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
  /// DISABLED: Auto-spot creation removed per user request
  /*
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
  */

  void _importFromCloud() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connecting to Google Drive...'),
        backgroundColor: AppColors.warningOrange,
      ),
    );
  }

  void _openPiece(Piece piece) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFScoreViewer(piece: piece),
      ),
    );
  }

  /// Helper method to build info rows for the import success dialog
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Create initial practice spot for imported piece
  /// DISABLED: Auto-spot creation removed per user request (duplicate method)
  /*
  Future<void> _createInitialPracticeSpot(Piece piece) async {
    try {
      // Create a default "Full Piece" spot for immediate practice availability
      final defaultSpot = Spot(
        id: 'default_${piece.id}_${DateTime.now().millisecondsSinceEpoch}',
        pieceId: piece.id,
        title: 'Full Piece',
        description: 'General practice for this imported piece. Open the PDF to create specific spots.',
        pageNumber: 1,
        x: 0.0,
        y: 0.0,
        width: 1.0,
        height: 1.0,
        priority: SpotPriority.medium,
        readinessLevel: ReadinessLevel.learning,
        color: SpotColor.blue, // Default to practice (blue)
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save the spot to database
      final spotService = SpotService();
      await spotService.saveSpot(defaultSpot);
      print('LibraryScreen: Created initial practice spot for piece "${piece.title}"');
    } catch (e) {
      print('LibraryScreen: Failed to create initial practice spot: $e');
      // Don't throw - spot creation is optional for import success
    }
  }
  */
}
