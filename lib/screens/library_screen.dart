// ==========================================
// LIBRARY_SCREEN.DART - MAIN MUSIC LIBRARY INTERFACE
// ==========================================
// This file contains the main library screen where users can view, search, sort,
// and manage their collection of PDF sheet music. It provides the primary interface
// for importing new pieces, organizing existing ones, and navigating to the PDF viewer.

// Core Flutter framework for UI components and material design
import 'package:flutter/material.dart';

// Riverpod state management for reactive UI and data management
// ConsumerStatefulWidget and ConsumerState enable state and provider integration
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Custom app theme definitions for consistent styling
import '../theme/app_theme.dart';

// PDF import and management service for handling file operations
import '../services/pdf_score_service.dart';

// Data model for musical pieces with metadata
import '../models/piece.dart';

// Custom animation utilities for smooth transitions and micro-interactions
import '../utils/animations.dart';

// Haptic feedback and user interaction feedback system
import '../utils/feedback_system.dart';

// Enhanced UI components with custom styling and animations
import '../widgets/enhanced_components.dart';

// Unified library provider for centralized piece and library state management
import '../providers/unified_library_provider.dart';

// Practice provider for tracking practice sessions and progress
import '../providers/practice_provider.dart';

// PDF viewer screen for displaying and annotating sheet music
import 'pdf_viewer/pdf_score_viewer.dart';

// Settings screen for app configuration and preferences
import 'settings/settings_screen.dart';

// ==========================================
// MUSIC PIECE MODEL CLASS
// ==========================================
// This class represents a single piece of sheet music in the library.
// It contains all metadata needed for display, organization, and practice tracking.
// This is a UI-focused model separate from the database Piece model.
class MusicPiece {
  // Unique identifier for the piece, used for database operations and references
  final String id;
  
  // Display name of the musical piece (e.g., "Moonlight Sonata")
  final String title;
  
  // Name of the composer or arranger (e.g., "Ludwig van Beethoven")
  final String composer;
  
  // Genre or category classification (e.g., "Classical", "Jazz", "Folk")
  final String category;
  
  // Timestamp when the piece was added to the library
  final DateTime dateAdded;
  
  // Total number of pages in the PDF document
  final int pages;
  
  // Practice completion percentage (0.0 to 1.0)
  // Calculated based on completed practice spots and time spent
  final double practiceProgress;
  
  // Difficulty level indicator (e.g., "Beginner", "Intermediate", "Advanced")
  final String difficulty;
  
  // Color associated with the category for visual organization
  final Color categoryColor;
  
  // Whether the user has marked this piece as a favorite
  final bool isFavorite;
  
  // Optional estimated performance duration (e.g., "3:45", "12 minutes")
  final String? duration;
  
  // Optional musical key signature (e.g., "C major", "F# minor")
  final String? key;
  
  // Total number of practice spots created on this piece
  final int spotsCount;
  
  // List of colors representing active practice spots
  // Used for visual indicators of spot difficulty and status
  final List<Color> spotColors;
  
  // Map counting spots by color for statistical display
  // Example: {Colors.red: 3, Colors.yellow: 5, Colors.green: 2}
  final Map<Color, int> spotColorCounts;

  // Constructor for creating a MusicPiece instance
  // Most fields are required, with sensible defaults for optional metadata
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
    this.isFavorite = false,      // Default to not favorite
    this.duration,                // Optional duration
    this.key,                     // Optional musical key
    this.spotsCount = 0,          // Default to no spots
    this.spotColors = const [],   // Default to empty spot colors
    this.spotColorCounts = const {}, // Default to empty color counts
  });
}

// ==========================================
// LIBRARY PROVIDER - STATE MANAGEMENT FOR MUSIC PIECES
// ==========================================
// This provider manages the list of MusicPiece objects for the library UI.
// It provides reactive state management using Riverpod's StateNotifierProvider.
// The LibraryNotifier handles CRUD operations and state updates for the library.
final libraryProvider = StateNotifierProvider<LibraryNotifier, List<MusicPiece>>((ref) {
  // Create and return a new LibraryNotifier instance
  // The provider will automatically manage the lifecycle and state updates
  return LibraryNotifier();
});

// ==========================================
// PIECES PROVIDER - DATABASE PIECE STORAGE
// ==========================================
// This provider stores the actual Piece objects with file paths and database data.
// It maintains a Map for quick lookups by piece ID and handles the relationship
// between UI MusicPiece objects and database Piece objects.
final piecesProvider = StateNotifierProvider<PiecesNotifier, Map<String, Piece>>((ref) {
  // Create and return a new PiecesNotifier instance
  // The Map uses piece ID as key for O(1) lookup performance
  return PiecesNotifier();
});

// ==========================================
// PIECES NOTIFIER - MANAGES DATABASE PIECE OBJECTS
// ==========================================
// Handles storage and retrieval of Piece objects that contain file paths
// and database metadata. This is separate from the UI-focused MusicPiece objects.
class PiecesNotifier extends StateNotifier<Map<String, Piece>> {
  // Initialize with empty Map - pieces are loaded as needed
  PiecesNotifier() : super({});

  // Add a new piece to the storage Map
  // @param piece: The Piece object to store, containing file path and metadata
  void addPiece(Piece piece) {
    // Create new state with the added piece using spread operator
    // This ensures immutability and triggers UI updates via Riverpod
    state = {...state, piece.id: piece};
  }

  // Retrieve a specific piece by its unique identifier
  // @param id: The unique ID of the piece to retrieve
  // @return: The Piece object if found, null otherwise
  Piece? getPiece(String id) {
    // Direct Map lookup - O(1) performance for piece retrieval
    return state[id];
  }
}

class LibraryNotifier extends StateNotifier<List<MusicPiece>> {
  LibraryNotifier() : super([]) {
    _loadLibrary();
  }

  void _loadLibrary() {
    // Load pieces from data service - no hardcoded demo data
    state = [];
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
          duration: piece.duration,
          key: piece.key,
          spotsCount: piece.spotsCount,
          spotColors: piece.spotColors,
          spotColorCounts: piece.spotColorCounts,
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
          duration: piece.duration,
          key: piece.key,
          spotsCount: piece.spotsCount,
          spotColors: piece.spotColors,
          spotColorCounts: piece.spotColorCounts,
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
    final piecesAsync = ref.watch(unifiedLibraryProvider);
    final userName = ref.watch(userNameProvider);
    
    return piecesAsync.when(
      loading: () => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading library: $error'),
              ElevatedButton(
                onPressed: () => ref.refresh(unifiedLibraryProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (pieces) {
        // Convert pieces to MusicPiece for UI compatibility
        final musicPieces = pieces.map((piece) {
          // Calculate spot color counts
          final Map<Color, int> colorCounts = {};
          for (final spot in piece.spots) {
            final color = spot.color.visualColor;
            colorCounts[color] = (colorCounts[color] ?? 0) + 1;
          }
          
          return MusicPiece(
            id: piece.id,
            title: piece.title,
            composer: piece.composer,
            category: 'Music',
            dateAdded: piece.createdAt,
            pages: piece.totalPages,
            practiceProgress: piece.readinessPercentage / 100.0, // Calculate from spots (0.0-1.0)
            difficulty: piece.difficulty.toString(),
            categoryColor: _getCategoryColor('Music'),
            isFavorite: false, // TODO: Implement favorites
            duration: piece.metadata?['duration'],
            key: piece.keySignature,
            spotsCount: piece.spots.length,
            spotColors: piece.spots.map((spot) => spot.color.visualColor).toSet().toList(),
            spotColorCounts: colorCounts,
          );
        }).toList();
        
        final filteredPieces = _getFilteredPieces(musicPieces);

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $userName!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                          fontSize: 15, // Reduced to fix overflow
                        ),
                      ),
                      Text(
                        'Music Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24, // Reduced to fix overflow
                        ),
                      ),
                    ],
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
                          const Spacer(),
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
        ); // Close the when statement
      }, // Close the data case
    ); // Close the when method
  }

  List<MusicPiece> _getFilteredPieces(List<MusicPiece> pieces) {
    var filtered = pieces;

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

  Widget _buildEnhancedQuickStats(List<Piece> pieces) {
    final totalPieces = pieces.length;
    final favorites = pieces.where((p) => p.isFavorite).length;
    final avgProgress = pieces.isEmpty ? 0.0 : 
      pieces.map((p) => p.readinessPercentage).reduce((a, b) => a + b) / pieces.length;

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
            '${avgProgress.toInt()}%',
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
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark 
                            ? Colors.white 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    child: Consumer(
                      builder: (context, ref, child) {
                        final piecesAsync = ref.watch(unifiedLibraryProvider);
                        return piecesAsync.when(
                          data: (pieces) {
                            // Find the corresponding Piece object from the provider
                            final currentPiece = pieces.firstWhere(
                              (p) => p.id == piece.id, 
                              orElse: () => pieces.isNotEmpty ? pieces.first : Piece(
                                id: piece.id,
                                title: piece.title,
                                composer: piece.composer,
                                difficulty: 1,
                                pdfFilePath: '',
                                spots: [],
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now(),
                                isFavorite: piece.isFavorite,
                              ),
                            );
                            return GestureDetector(
                              key: ValueKey('favorite_${piece.id}_${currentPiece.isFavorite}'),
                              onTap: () {
                                FeedbackSystem.light();
                                ref.read(unifiedLibraryProvider.notifier).toggleFavorite(piece.id);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    print('LibraryScreen: Rendering heart for piece ${currentPiece.title} (${currentPiece.id}) - isFavorite: ${currentPiece.isFavorite}');
                                    return Icon(
                                      currentPiece.isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: currentPiece.isFavorite 
                                          ? AppColors.errorRed 
                                          : (Theme.of(context).brightness == Brightness.dark 
                                              ? Colors.white.withOpacity(0.7) 
                                              : AppColors.textSecondary),
                                      size: 16,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          loading: () => Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (err, stack) => Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error, size: 16),
                          ),
                        );
                      },
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      piece.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      piece.composer,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[300]
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (piece.duration != null || piece.key != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (piece.duration != null) ...[
                            Icon(Icons.access_time, size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                piece.duration!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (piece.duration != null && piece.key != null) ...[
                            const SizedBox(width: 4),
                            Text('•', style: TextStyle(fontSize: 9, color: AppColors.textSecondary)),
                            const SizedBox(width: 4),
                          ],
                          if (piece.key != null) ...[
                            Icon(Icons.music_note, size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                piece.key!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (piece.spotsCount > 0) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              constraints: const BoxConstraints(maxWidth: 120),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: _buildSpotColorDisplay(piece.spotColorCounts),
                            ),
                          ],
                        ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Spacer(),
                      Text(
                        '${piece.pages}p',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  EnhancedProgressIndicator(
                    value: piece.practiceProgress,
                    height: 3,
                    gradient: LinearGradient(
                      colors: [piece.categoryColor, piece.categoryColor.withOpacity(0.7)],
                    ),
                  ),
                ],
                ),
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
                  Consumer(
                    builder: (context, ref, child) {
                      final piecesAsync = ref.watch(unifiedLibraryProvider);
                      return piecesAsync.when(
                        data: (pieces) {
                          // Find the corresponding Piece object from the provider
                          final currentPiece = pieces.firstWhere(
                            (p) => p.id == piece.id, 
                            orElse: () => pieces.isNotEmpty ? pieces.first : Piece(
                              id: piece.id,
                              title: piece.title,
                              composer: piece.composer,
                              difficulty: 1,
                              pdfFilePath: '',
                              spots: [],
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              isFavorite: piece.isFavorite,
                            ),
                          );
                          return IconButton(
                            key: ValueKey('favorite_btn_${piece.id}_${currentPiece.isFavorite}'),
                            onPressed: () => ref.read(unifiedLibraryProvider.notifier).toggleFavorite(piece.id),
                            icon: Builder(
                              builder: (context) {
                                print('LibraryScreen: Rendering heart button for piece ${currentPiece.title} (${currentPiece.id}) - isFavorite: ${currentPiece.isFavorite}');
                                return Icon(
                                  currentPiece.isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: currentPiece.isFavorite 
                                      ? AppColors.errorRed 
                                      : (Theme.of(context).brightness == Brightness.dark 
                                          ? Colors.white.withOpacity(0.7) 
                                          : AppColors.textSecondary),
                                  size: 20,
                                );
                              },
                            ),
                          );
                        },
                        loading: () => const IconButton(
                          onPressed: null,
                          icon: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (err, stack) => const IconButton(
                          onPressed: null,
                          icon: Icon(Icons.error, size: 20),
                        ),
                      );
                    },
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
              if (piece.duration != null || piece.key != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (piece.duration != null) ...[
                      Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        piece.duration!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (piece.duration != null && piece.key != null)
                      const Spacer(),
                    if (piece.key != null) ...[
                      Icon(Icons.music_note, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        piece.key!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 12),

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
              textAlign: TextAlign.center,
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
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _openPiece(MusicPiece piece) async {
    try {
      FeedbackSystem.medium();
      
      // Get the actual Piece object from the unified library
      final libraryState = ref.read(unifiedLibraryProvider);
      if (!libraryState.hasValue) return;
      
      final actualPiece = libraryState.value!.firstWhere(
        (p) => p.id == piece.id,
        orElse: () => throw Exception('Piece not found in library'),
      );
      
      if (actualPiece.pdfFilePath.isNotEmpty) {
        print('LibraryScreen: Opening piece ${actualPiece.title} with path: ${actualPiece.pdfFilePath}');
        
        // Navigate with enhanced animation
        await Navigator.of(context).push(
          AppAnimations.createRoute<void>(
            page: PDFScoreViewer(piece: actualPiece),
            duration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        // For demo pieces or pieces without valid paths, show enhanced dialog
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
    } catch (e) {
      print('LibraryScreen: Error opening piece: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening piece: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Sort Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable content with better constraints
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sort By',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...['Recently Added', 'Title', 'Composer', 'Progress']
                        .map((sortOption) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                sortOption,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              trailing: _sortBy == sortOption 
                                  ? const Icon(Icons.check, color: AppColors.primaryPurple) 
                                  : null,
                              onTap: () {
                                setState(() {
                                  _sortBy = sortOption;
                                });
                                Navigator.pop(context);
                              },
                            )),
                    const SizedBox(height: 32), // Extra padding at bottom
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Sort Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable content with better constraints
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Recently Added', 'Title', 'Composer', 'Progress']
                      .map((sortOption) => ListTile(
                            leading: Icon(
                              _getSortIcon(sortOption),
                              color: AppColors.primaryPurple,
                            ),
                            title: Text(
                              sortOption,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
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
              ),
            ),
            const SizedBox(height: 32), // Extra padding at bottom
          ],
        ),
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
        contentPadding: EdgeInsets.zero,
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
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        // Show form to enter composer and difficulty
        final pieceInfo = await _showPieceInfoDialog(piece.title);
        
        if (pieceInfo != null) {
          // Update piece with user input
          final updatedPiece = Piece(
            id: piece.id,
            title: piece.title,
            composer: pieceInfo['composer'] ?? piece.composer,
            difficulty: pieceInfo['difficulty'] ?? piece.difficulty,
            totalPages: piece.totalPages,
            createdAt: piece.createdAt,
            updatedAt: DateTime.now(),
            pdfFilePath: piece.pdfFilePath,
            keySignature: piece.keySignature,
            metadata: piece.metadata,
            spots: [], // Initialize with empty spots list
          );

          // Add to unified library (this automatically handles both database and UI)
          await ref.read(unifiedLibraryProvider.notifier).addPiece(updatedPiece);

          // Refresh practice provider to include the new piece in practice dashboard
          ref.read(practiceProvider.notifier).refresh();

          // Show success popup
          if (mounted) {
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
                    _buildInfoRow('Title:', updatedPiece.title),
                    _buildInfoRow('Composer:', updatedPiece.composer),
                    if (updatedPiece.keySignature != null && updatedPiece.keySignature!.isNotEmpty)
                      _buildInfoRow('Key:', updatedPiece.keySignature!),
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
                      // Convert Piece to MusicPiece for _openPiece
                      final Map<Color, int> colorCounts = {};
                      for (final spot in updatedPiece.spots) {
                        final color = spot.color.visualColor;
                        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
                      }
                      
                      final musicPiece = MusicPiece(
                        id: updatedPiece.id,
                        title: updatedPiece.title,
                        composer: updatedPiece.composer,
                        category: 'Music',
                        dateAdded: updatedPiece.createdAt,
                        pages: updatedPiece.totalPages,
                        practiceProgress: updatedPiece.readinessPercentage / 100.0,
                        difficulty: updatedPiece.difficulty.toString(),
                        categoryColor: _getCategoryColor('Music'),
                        isFavorite: false,
                        duration: updatedPiece.metadata?['duration'],
                        key: updatedPiece.keySignature,
                        spotsCount: updatedPiece.spots.length,
                        spotColors: updatedPiece.spots.map((spot) => spot.color.visualColor).toSet().toList(),
                        spotColorCounts: colorCounts,
                      );
                      _openPiece(musicPiece);
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

          FeedbackSystem.showSuccess(
            context,
            'Successfully imported "${updatedPiece.title}"',
            action: () {
              // Convert Piece to MusicPiece for _openPiece
              final Map<Color, int> colorCounts = {};
              for (final spot in updatedPiece.spots) {
                final color = spot.color.visualColor;
                colorCounts[color] = (colorCounts[color] ?? 0) + 1;
              }
              
              final musicPiece = MusicPiece(
                id: updatedPiece.id,
                title: updatedPiece.title,
                composer: updatedPiece.composer,
                category: 'Music',
                dateAdded: updatedPiece.createdAt,
                pages: updatedPiece.totalPages,
                practiceProgress: updatedPiece.readinessPercentage / 100.0,
                difficulty: updatedPiece.difficulty.toString(),
                categoryColor: _getCategoryColor('Music'),
                isFavorite: false,
                duration: updatedPiece.metadata?['duration'],
                key: updatedPiece.keySignature,
                spotsCount: updatedPiece.spots.length,
                spotColors: updatedPiece.spots.map((spot) => spot.color.visualColor).toSet().toList(),
                spotColorCounts: colorCounts,
              );
              _openPiece(musicPiece);
            },
            actionLabel: 'Open',
          );
        } else {
          // User cancelled the info dialog
          FeedbackSystem.showWarning(
            context,
            'Import cancelled',
          );
        }
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

  String _buildSpotColorText(Map<Color, int> colorCounts) {
    if (colorCounts.isEmpty) return '';
    
    final List<String> colorTexts = [];
    
    colorCounts.forEach((color, count) {
      String colorName = _getColorName(color);
      colorTexts.add('$count $colorName');
    });
    
    return colorTexts.join(', ');
  }

  Widget _buildSpotColorDisplay(Map<Color, int> colorCounts) {
    if (colorCounts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final List<Widget> colorWidgets = [];
    
    colorCounts.forEach((color, count) {
      colorWidgets.add(
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
    
    return Wrap(
      spacing: 3,
      runSpacing: 2,
      children: colorWidgets,
    );
  }
  
  String _getColorName(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.green) return 'green';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.yellow) return 'yellow';
    return 'spot';
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

  Future<Map<String, dynamic>?> _showPieceInfoDialog(String title) async {
    final composerController = TextEditingController();
    int selectedDifficulty = 3; // Default to medium difficulty

    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Piece Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Title: $title',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Composer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: composerController,
                  decoration: InputDecoration(
                    hintText: 'Enter composer name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.primaryPurple),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Difficulty Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryPurple.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Easy'),
                          Text('$selectedDifficulty/5'),
                          const Text('Hard'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: selectedDifficulty.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: AppColors.primaryPurple,
                        onChanged: (value) {
                          setState(() {
                            selectedDifficulty = value.round();
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < selectedDifficulty ? Icons.star : Icons.star_border,
                            color: AppColors.primaryPurple,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop({
                  'composer': composerController.text.trim().isEmpty 
                      ? 'Unknown Composer' 
                      : composerController.text.trim(),
                  'difficulty': selectedDifficulty,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
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
