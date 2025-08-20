import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/pdf_score_service.dart';
import '../models/piece.dart';
import '../utils/animations.dart';
import '../utils/feedback_system.dart';
import '../widgets/enhanced_components.dart';
import 'pdf_viewer/pdf_score_viewer.dart';

// Music piece model
class MusicPiece {
  final String id;
  final String title;
  final String composer;
  final String category;
  final DateTime dateAdded;
  final int pages;
  final double practiceProgress;
  final String difficulty;
  final Color categoryColor;
  final bool isFavorite;

  MusicPiece({
    required this.id,
    required this.title,
    required this.composer,
    required this.category,
    required this.dateAdded,
    required this.pages,
    required this.practiceProgress,
    required this.difficulty,
    required this.categoryColor,
    this.isFavorite = false,
  });
}

// Library provider
final libraryProvider = StateNotifierProvider<LibraryNotifier, List<MusicPiece>>((ref) {
  return LibraryNotifier();
});

// Pieces provider to store actual Piece objects with PDF paths
final piecesProvider = StateNotifierProvider<PiecesNotifier, Map<String, Piece>>((ref) {
  return PiecesNotifier();
});

class PiecesNotifier extends StateNotifier<Map<String, Piece>> {
  PiecesNotifier() : super({});

  void addPiece(Piece piece) {
    state = {...state, piece.id: piece};
  }

  Piece? getPiece(String id) {
    return state[id];
  }
}

class LibraryNotifier extends StateNotifier<List<MusicPiece>> {
  LibraryNotifier() : super([]) {
    _loadLibrary();
  }

  void _loadLibrary() {
    // Load with beautiful demo pieces
    state = [
      MusicPiece(
        id: '1',
        title: 'Nocturne in E-flat major',
        composer: 'Frédéric Chopin',
        category: 'Classical',
        dateAdded: DateTime.now().subtract(const Duration(days: 5)),
        pages: 4,
        practiceProgress: 0.85,
        difficulty: 'Intermediate',
        categoryColor: AppColors.primaryPurple,
        isFavorite: true,
      ),
      MusicPiece(
        id: '2',
        title: 'Clair de Lune',
        composer: 'Claude Debussy',
        category: 'Classical',
        dateAdded: DateTime.now().subtract(const Duration(days: 12)),
        pages: 6,
        practiceProgress: 0.92,
        difficulty: 'Advanced',
        categoryColor: AppColors.primaryPurple,
        isFavorite: true,
      ),
      MusicPiece(
        id: '3',
        title: 'Autumn Leaves',
        composer: 'Joseph Kosma',
        category: 'Jazz',
        dateAdded: DateTime.now().subtract(const Duration(days: 3)),
        pages: 3,
        practiceProgress: 0.67,
        difficulty: 'Intermediate',
        categoryColor: AppColors.warningOrange,
      ),
      MusicPiece(
        id: '4',
        title: 'Moonlight Sonata',
        composer: 'Ludwig van Beethoven',
        category: 'Classical',
        dateAdded: DateTime.now().subtract(const Duration(days: 20)),
        pages: 8,
        practiceProgress: 0.73,
        difficulty: 'Advanced',
        categoryColor: AppColors.primaryPurple,
      ),
      MusicPiece(
        id: '5',
        title: 'The Girl from Ipanema',
        composer: 'Antonio Carlos Jobim',
        category: 'Bossa Nova',
        dateAdded: DateTime.now().subtract(const Duration(days: 7)),
        pages: 2,
        practiceProgress: 0.45,
        difficulty: 'Beginner',
        categoryColor: AppColors.successGreen,
      ),
      MusicPiece(
        id: '6',
        title: 'Imagine',
        composer: 'John Lennon',
        category: 'Pop',
        dateAdded: DateTime.now().subtract(const Duration(days: 1)),
        pages: 3,
        practiceProgress: 0.28,
        difficulty: 'Beginner',
        categoryColor: AppColors.errorRed,
      ),
    ];
  }

  void toggleFavorite(String pieceId) {
    state = state.map((piece) {
      if (piece.id == pieceId) {
        return MusicPiece(
          id: piece.id,
          title: piece.title,
          composer: piece.composer,
          category: piece.category,
          dateAdded: piece.dateAdded,
          pages: piece.pages,
          practiceProgress: piece.practiceProgress,
          difficulty: piece.difficulty,
          categoryColor: piece.categoryColor,
          isFavorite: !piece.isFavorite,
        );
      }
      return piece;
    }).toList();
  }

  void updateProgress(String pieceId, double newProgress) {
    state = state.map((piece) {
      if (piece.id == pieceId) {
        return MusicPiece(
          id: piece.id,
          title: piece.title,
          composer: piece.composer,
          category: piece.category,
          dateAdded: piece.dateAdded,
          pages: piece.pages,
          practiceProgress: newProgress,
          difficulty: piece.difficulty,
          categoryColor: piece.categoryColor,
          isFavorite: piece.isFavorite,
        );
      }
      return piece;
    }).toList();
  }

  void addPiece(MusicPiece piece) {
    state = [...state, piece];
  }
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortBy = 'Recently Added';
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Start animations
    _animationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pieces = ref.watch(libraryProvider);
    final filteredPieces = _getFilteredPieces(pieces);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Enhanced App Bar with Gradient
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primaryPurple,
              flexibleSpace: FlexibleSpaceBar(
                title: AppAnimations.fadeScale(
                  controller: _animationController,
                  child: const Text(
                    'Music Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.accentPurple,
                        AppColors.successGreen,
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Animated background circles
                      Positioned(
                        right: -80,
                        top: -80,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(seconds: 3),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: -40,
                        bottom: -40,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(seconds: 2),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Music notes animation
                      Positioned(
                        top: 60,
                        right: 40,
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(seconds: 4),
                          tween: Tween(begin: 0.0, end: 1.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, -20 * value),
                              child: Opacity(
                                opacity: value,
                                child: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 30,
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
            ),

            // Content with Staggered Animations
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats with Animation
                    AppAnimations.staggeredItem(
                      controller: _animationController,
                      index: 0,
                      child: _buildEnhancedQuickStats(pieces),
                    ),
                    
                    const SizedBox(height: 24),

                    // Enhanced Search Bar
                    AppAnimations.staggeredItem(
                      controller: _animationController,
                      index: 1,
                      child: _buildEnhancedSearchBar(),
                    ),
                    
                    const SizedBox(height: 16),

                    // Filter and Sort Row with Animation
                    AppAnimations.staggeredItem(
                      controller: _animationController,
                      index: 2,
                      child: Row(
                        children: [
                          Expanded(child: _buildEnhancedCategoryFilter()),
                          const SizedBox(width: 12),
                          _buildEnhancedSortDropdown(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Pieces Grid with Staggered Animation
                    if (filteredPieces.isEmpty)
                      AppAnimations.staggeredItem(
                        controller: _animationController,
                        index: 3,
                        child: _buildEmptyState(),
                      )
                    else
                      _buildAnimatedPiecesGrid(filteredPieces),
                    
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.elasticOut,
        )),
        child: EnhancedFAB(
          onPressed: _importPDF,
          icon: Icons.add,
          label: 'Import PDF',
          gradient: const LinearGradient(
            colors: [AppColors.successGreen, AppColors.primaryPurple],
          ),
        ),
      ),
    );
  }

  List<MusicPiece> _getFilteredPieces(List<MusicPiece> pieces) {
    var filtered = pieces;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((piece) => piece.category == _selectedCategory).toList();
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
        filtered.sort((a, b) => b.practiceProgress.compareTo(a.practiceProgress));
        break;
      case 'Recently Added':
      default:
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
    }

    return filtered;
  }

  Widget _buildEnhancedQuickStats(List<MusicPiece> pieces) {
    final totalPieces = pieces.length;
    final favorites = pieces.where((p) => p.isFavorite).length;
    final avgProgress = pieces.isEmpty ? 0.0 : 
      pieces.map((p) => p.practiceProgress).reduce((a, b) => a + b) / pieces.length;

    return Row(
      children: [
        Expanded(
          child: _buildEnhancedStatCard(
            'Total Pieces',
            '$totalPieces',
            Icons.library_music,
            AppColors.primaryPurple,
            0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedStatCard(
            'Favorites',
            '$favorites',
            Icons.favorite,
            AppColors.errorRed,
            1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildEnhancedStatCard(
            'Avg Progress',
            '${(avgProgress * 100).toInt()}%',
            Icons.trending_up,
            AppColors.successGreen,
            2,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(String title, String value, IconData icon, Color color, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animation, child) {
        return Transform.scale(
          scale: animation,
          child: EnhancedCard(
            padding: const EdgeInsets.all(16),
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800 + (index * 200)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, iconAnimation, child) {
                    return Transform.scale(
                      scale: iconAnimation,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 1000 + (index * 200)),
                  tween: Tween(begin: 0.0, end: double.parse(value.replaceAll('%', ''))),
                  builder: (context, numberAnimation, child) {
                    return Text(
                      title.contains('Progress') 
                          ? '${numberAnimation.toInt()}%' 
                          : '${numberAnimation.toInt()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSearchBar() {
    return EnhancedSearchBar(
      controller: _searchController,
      hintText: 'Search your music library...',
      showFilters: true,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      onClear: () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      },
      onFilterTap: () {
        _showFilterBottomSheet();
      },
    );
  }

  Widget _buildEnhancedCategoryFilter() {
    final categories = ['All', 'Classical', 'Jazz', 'Pop', 'Bossa Nova'];
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, animation, child) {
                return Transform.scale(
                  scale: animation,
                  child: EnhancedCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: EdgeInsets.zero,
                    backgroundColor: isSelected 
                        ? AppColors.primaryPurple 
                        : Colors.white,
                    onTap: () {
                      FeedbackSystem.selection();
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedSortDropdown() {
    return EnhancedCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: EdgeInsets.zero,
      onTap: () => _showSortBottomSheet(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sort,
            color: AppColors.primaryPurple,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _sortBy,
            style: const TextStyle(
              color: AppColors.primaryPurple,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPiecesGrid(List<MusicPiece> pieces) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: pieces.length,
      itemBuilder: (context, index) {
        return AppAnimations.staggeredItem(
          controller: _animationController,
          index: index + 4, // Offset for other animated items
          child: _buildEnhancedPieceCard(pieces[index]),
        );
      },
    );
  }

  Widget _buildEnhancedPieceCard(MusicPiece piece) {
    return EnhancedCard(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      onTap: () => _openPiece(piece),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover art area with gradient
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    piece.categoryColor,
                    piece.categoryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Stack(
                children: [
                  // Musical note pattern
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(
                        painter: MusicalNotesPainter(),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        FeedbackSystem.light();
                        ref.read(libraryProvider.notifier).toggleFavorite(piece.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          piece.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: piece.isFavorite ? AppColors.errorRed : AppColors.textSecondary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Play button overlay
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        FeedbackSystem.medium();
                        _openPiece(piece);
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: AppColors.primaryPurple,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    piece.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    piece.composer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      EnhancedBadge(
                        text: piece.difficulty,
                        backgroundColor: piece.categoryColor.withOpacity(0.1),
                        textColor: piece.categoryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      ),
                      const Spacer(),
                      Text(
                        '${piece.pages}p',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  EnhancedProgressIndicator(
                    value: piece.practiceProgress,
                    height: 4,
                    gradient: LinearGradient(
                      colors: [piece.categoryColor, piece.categoryColor.withOpacity(0.7)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
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
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
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
              selectedColor: AppColors.successGreen.withOpacity(0.2),
              checkmarkColor: AppColors.successGreen,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.successGreen : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
      ),
      child: DropdownButton<String>(
        value: _sortBy,
        underline: Container(),
        icon: Icon(Icons.sort, color: AppColors.textSecondary),
        items: ['Recently Added', 'Title', 'Composer', 'Progress']
            .map((sort) => DropdownMenuItem(
                  value: sort,
                  child: Text(sort, style: const TextStyle(fontSize: 12)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _sortBy = value!;
          });
        },
      ),
    );
  }

  Widget _buildPiecesGrid(List<MusicPiece> pieces) {
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

  Widget _buildPieceCard(MusicPiece piece) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openPiece(piece),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with favorite button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: piece.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: piece.categoryColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.read(libraryProvider.notifier).toggleFavorite(piece.id),
                    icon: Icon(
                      piece.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: piece.isFavorite ? AppColors.errorRed : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title and composer
              Text(
                piece.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                piece.composer,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Category and difficulty
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: piece.categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      piece.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: piece.categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    piece.difficulty,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${(piece.practiceProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: piece.categoryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: piece.practiceProgress,
                      backgroundColor: piece.categoryColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(piece.categoryColor),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Pages info
              Row(
                children: [
                  Icon(Icons.description, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${piece.pages} pages',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 1000),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, animation, child) {
              return Transform.scale(
                scale: animation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.accentPurple],
                    ),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.library_music,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Your music library is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Import your first PDF to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          EnhancedButton(
            text: 'Import PDF',
            icon: Icons.add,
            onPressed: _importPDF,
            isFullWidth: false,
          ),
        ],
      ),
    );
  }

  void _openPiece(MusicPiece piece) async {
    FeedbackSystem.medium();
    
    // Get the actual Piece object from the provider
    final actualPiece = ref.read(piecesProvider.notifier).getPiece(piece.id);
    
    if (actualPiece != null && actualPiece.pdfFilePath.isNotEmpty) {
      // Navigate with enhanced animation
      await Navigator.of(context).push(
        AppAnimations.createRoute<void>(
          page: PDFScoreViewer(piece: actualPiece),
          duration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // For demo pieces, show enhanced dialog
      showDialog(
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
                  color: piece.categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note, color: piece.categoryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  piece.title,
                  style: const TextStyle(
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
              Text('Composer: ${piece.composer}'),
              const SizedBox(height: 8),
              Text('Category: ${piece.category}'),
              Text('Difficulty: ${piece.difficulty}'),
              Text('Pages: ${piece.pages}'),
              const SizedBox(height: 16),
              Text(
                'Practice Progress: ${(piece.practiceProgress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: piece.categoryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This is a demo piece. Import your own PDF files to open and practice with the full PDF viewer.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _importPDF();
              },
              style: FilledButton.styleFrom(backgroundColor: piece.categoryColor),
              child: const Text('Import PDF'),
            ),
          ],
        ),
      );
    }
  }

  void _showFilterBottomSheet() {
    FeedbackSystem.showCustomBottomSheet(
      context,
      title: 'Filter & Sort',
      content: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', 'Classical', 'Jazz', 'Pop', 'Bossa Nova']
                  .map((category) => GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          Navigator.pop(context);
                        },
                        child: EnhancedBadge(
                          text: category,
                          backgroundColor: _selectedCategory == category
                              ? AppColors.primaryPurple
                              : Colors.grey.shade200,
                          textColor: _selectedCategory == category
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...['Recently Added', 'Title', 'Composer', 'Progress']
                .map((sortOption) => ListTile(
                      leading: Radio<String>(
                        value: sortOption,
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                          });
                          Navigator.pop(context);
                        },
                        activeColor: AppColors.primaryPurple,
                      ),
                      title: Text(sortOption),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    FeedbackSystem.showCustomBottomSheet(
      context,
      title: 'Sort Library',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ['Recently Added', 'Title', 'Composer', 'Progress']
            .map((sortOption) => ListTile(
                  leading: Icon(
                    _getSortIcon(sortOption),
                    color: AppColors.primaryPurple,
                  ),
                  title: Text(sortOption),
                  trailing: _sortBy == sortOption
                      ? const Icon(
                          Icons.check,
                          color: AppColors.primaryPurple,
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _sortBy = sortOption;
                    });
                    Navigator.pop(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  IconData _getSortIcon(String sortOption) {
    switch (sortOption) {
      case 'Recently Added':
        return Icons.access_time;
      case 'Title':
        return Icons.sort_by_alpha;
      case 'Composer':
        return Icons.person;
      case 'Progress':
        return Icons.trending_up;
      default:
        return Icons.sort;
    }
  }

  void _importPDF() {
    showDialog(
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
              child: const Icon(
                Icons.upload_file,
                color: AppColors.successGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Import PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose how you\'d like to import your music:',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            EnhancedCard(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                _importFromDevice();
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.folder,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select PDF from your device',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            EnhancedCard(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                _importFromCloud();
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.cloud,
                      color: AppColors.warningOrange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Cloud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Import from Google Drive',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _importFromDevice() async {
    try {
      FeedbackSystem.showLoadingOverlay(context, 'Opening device file picker...');
      
      // Small delay to show loading
      await Future.delayed(const Duration(milliseconds: 500));
      
      Navigator.of(context).pop(); // Close loading dialog

      // Use the enhanced PDF service to import
      final piece = await PDFScoreService.importPDFAsPiece();
      
      if (piece != null) {
        // Store the actual Piece object
        ref.read(piecesProvider.notifier).addPiece(piece);

        // Create display MusicPiece for the UI
        final musicPiece = MusicPiece(
          id: piece.id,
          title: piece.title,
          composer: piece.composer,
          category: piece.tags.isNotEmpty ? piece.tags.first : 'Uncategorized',
          dateAdded: piece.createdAt,
          pages: piece.totalPages,
          practiceProgress: 0.0,
          difficulty: piece.difficulty.toString(),
          categoryColor: _getCategoryColor(piece.tags.isNotEmpty ? piece.tags.first : 'Uncategorized'),
          isFavorite: false,
        );

        // Add the piece to the library state
        ref.read(libraryProvider.notifier).addPiece(musicPiece);

        FeedbackSystem.showSuccess(
          context,
          'Successfully imported "${piece.title}"',
          action: () => _openPiece(musicPiece),
          actionLabel: 'Open',
        );
      } else {
        FeedbackSystem.showWarning(
          context,
          'Import cancelled or no file selected',
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading if still open
      FeedbackSystem.showError(
        context,
        'Error importing PDF: ${e.toString()}',
        action: () => _importFromDevice(),
        actionLabel: 'Retry',
      );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'classical':
      case 'baroque':
        return AppColors.primaryPurple;
      case 'jazz':
      case 'blues':
        return AppColors.warningOrange;
      case 'romantic':
        return AppColors.errorRed;
      case 'modern':
      case 'contemporary':
        return AppColors.successGreen;
      default:
        return AppColors.textSecondary;
    }
  }

  void _importFromCloud() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting to Google Drive...'),
          backgroundColor: AppColors.warningOrange,
        ),
      );

      // Show cloud import dialog with options
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cloud, color: AppColors.warningOrange),
              const SizedBox(width: 8),
              const Text('Cloud Import'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose your cloud storage provider:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blue),
                title: const Text('Google Drive'),
                subtitle: const Text('Import from Google Drive'),
                onTap: () => Navigator.pop(context, true),
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.purple),
                title: const Text('OneDrive'),
                subtitle: const Text('Import from OneDrive'),
                onTap: () {
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OneDrive support coming soon!'),
                      backgroundColor: AppColors.warningOrange,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.orange),
                title: const Text('iCloud'),
                subtitle: const Text('Import from iCloud Drive'),
                onTap: () {
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('iCloud support coming soon!'),
                      backgroundColor: AppColors.warningOrange,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result == true) {
        // For now, fall back to device picker until cloud APIs are integrated
        FeedbackSystem.showWarning(
          context,
          'Cloud integration coming soon! Using device picker instead...',
        );
        _importFromDevice();
      }
    } catch (e) {
      FeedbackSystem.showError(
        context,
        'Error connecting to cloud: ${e.toString()}',
      );
    }
  }
}

/// Custom painter for musical notes pattern
class MusicalNotesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw musical notes pattern
    const noteSize = 8.0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        final x = (size.width / 3) * i + 20;
        final y = (size.height / 2) * j + 30;
        
        // Draw note head
        canvas.drawCircle(Offset(x, y), noteSize / 2, paint);
        
        // Draw note stem
        canvas.drawRect(
          Rect.fromLTWH(x + noteSize / 2 - 1, y - noteSize * 2, 2, noteSize * 2),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
