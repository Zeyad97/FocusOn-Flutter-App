import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/piece.dart';
import '../models/spot.dart';
import '../models/bookmark.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Enhanced search functionality with filters and multiple result types
class EnhancedSearchDelegate extends SearchDelegate<Piece?> {
  final WidgetRef ref;

  EnhancedSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => 'Search pieces, spots, bookmarks...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: () => _showFilterDialog(context),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentSearches();
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<SearchResults>(
      future: _performSearch(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: AppColors.errorRed),
                const SizedBox(height: 16),
                Text('Error searching: ${snapshot.error}'),
              ],
            ),
          );
        }

        final results = snapshot.data!;
        final totalResults = results.pieces.length + 
                           results.spots.length + 
                           results.bookmarks.length;

        if (totalResults == 0) {
          return _buildNoResults();
        }

        return _buildResultsList(results);
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No results for "$query"',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try searching for:\n• Piece titles or composers\n• Practice spots\n• Bookmark names',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(SearchResults results) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Found ${results.pieces.length} pieces, ${results.spots.length} spots, ${results.bookmarks.length} bookmarks',
            style: TextStyle(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Pieces section
        if (results.pieces.isNotEmpty) ...[
          _buildSectionHeader('Pieces', results.pieces.length, Icons.library_music),
          ...results.pieces.map((piece) => _buildPieceResult(piece)),
          const SizedBox(height: 16),
        ],

        // Spots section
        if (results.spots.isNotEmpty) ...[
          _buildSectionHeader('Practice Spots', results.spots.length, Icons.location_on),
          ...results.spots.map((spot) => _buildSpotResult(spot)),
          const SizedBox(height: 16),
        ],

        // Bookmarks section
        if (results.bookmarks.isNotEmpty) ...[
          _buildSectionHeader('Bookmarks', results.bookmarks.length, Icons.bookmark),
          ...results.bookmarks.map((bookmark) => _buildBookmarkResult(bookmark)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieceResult(Piece piece) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryPurple,
          child: Text(
            piece.title[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          piece.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(piece.composer),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${piece.readinessPercentage.round()}%',
                style: TextStyle(
                  color: AppColors.successGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          close(context, piece);
        },
      ),
    );
  }

  Widget _buildSpotResult(Spot spot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getSpotColor(spot.color),
          child: Text(
            'P${spot.pageNumber}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          spot.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${spot.description ?? 'Practice spot'} • Page ${spot.pageNumber}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(spot.priority),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            spot.priority.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Navigate to the piece and page with this spot
          _navigateToSpot(spot);
        },
      ),
    );
  }

  Widget _buildBookmarkResult(Bookmark bookmark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue,
          child: Text(
            'P${bookmark.pageNumber}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          bookmark.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text('${bookmark.description ?? 'Bookmark'} • Page ${bookmark.pageNumber}'),
        trailing: const Icon(Icons.bookmark, color: AppColors.primaryBlue),
        onTap: () {
          // Navigate to the piece and page with this bookmark
          _navigateToBookmark(bookmark);
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'Search your music library',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Find pieces, practice spots, and bookmarks',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<SearchResults> _performSearch(String query) async {
    if (query.isEmpty) {
      return SearchResults(pieces: [], spots: [], bookmarks: []);
    }

    final dbService = DatabaseService();
    
    // Search pieces
    final allPieces = await dbService.getAllPieces();
    final matchingPieces = allPieces.where((piece) {
      final searchText = query.toLowerCase();
      return piece.title.toLowerCase().contains(searchText) ||
             piece.composer.toLowerCase().contains(searchText) ||
             (piece.genre?.toLowerCase().contains(searchText) ?? false) ||
             (piece.keySignature?.toLowerCase().contains(searchText) ?? false);
    }).toList();

    // Search spots
    final allSpots = await dbService.getAllSpots();
    final matchingSpots = allSpots.where((spot) {
      final searchText = query.toLowerCase();
      return spot.title.toLowerCase().contains(searchText) ||
             (spot.description?.toLowerCase().contains(searchText) ?? false);
    }).toList();

    // Search bookmarks
    final allBookmarks = await dbService.getAllBookmarks();
    final matchingBookmarks = allBookmarks.where((bookmark) {
      final searchText = query.toLowerCase();
      return bookmark.title.toLowerCase().contains(searchText) ||
             (bookmark.description?.toLowerCase().contains(searchText) ?? false);
    }).toList();

    return SearchResults(
      pieces: matchingPieces,
      spots: matchingSpots,
      bookmarks: matchingBookmarks,
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Pieces'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Practice Spots'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Bookmarks'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _navigateToSpot(Spot spot) {
    // TODO: Implement navigation to specific spot
    print('Navigate to spot: ${spot.title} on page ${spot.pageNumber}');
  }

  void _navigateToBookmark(Bookmark bookmark) {
    // TODO: Implement navigation to specific bookmark
    print('Navigate to bookmark: ${bookmark.title} on page ${bookmark.pageNumber}');
  }

  Color _getSpotColor(SpotColor color) {
    return AppColors.getSpotColorByEnum(color);
  }

  Color _getPriorityColor(SpotPriority priority) {
    return switch (priority) {
      SpotPriority.low => AppColors.successGreen,
      SpotPriority.medium => AppColors.warningYellow,
      SpotPriority.high => AppColors.errorRed,
      SpotPriority.critical => AppColors.spotRed,
    };
  }
}

/// Search results container
class SearchResults {
  final List<Piece> pieces;
  final List<Spot> spots;
  final List<Bookmark> bookmarks;

  SearchResults({
    required this.pieces,
    required this.spots,
    required this.bookmarks,
  });
}

/// Extension for database service to get all bookmarks
extension DatabaseServiceExtension on DatabaseService {
  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final maps = await db.query('bookmarks', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) => Bookmark.fromMap(maps[i]));
  }
}
