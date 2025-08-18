import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../theme/app_theme.dart';
import '../../models/piece.dart';
import '../../models/spot.dart';
import '../pdf_viewer/pdf_score_viewer.dart';
import 'widgets/piece_card.dart';
import 'widgets/library_header.dart';
import 'widgets/practice_status_bar.dart';
import 'widgets/quick_action_chips.dart';
import 'widgets/import_pdf_dialog.dart';

/// Main library screen - hub for PDF management and quick practice access
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.grid;
  SortOrder _sortOrder = SortOrder.priority;
  bool _isLoading = true;
  List<Piece> _pieces = [];
  List<Piece> _filteredPieces = [];

  @override
  void initState() {
    super.initState();
    _loadPieces();
  }

  Future<void> _loadPieces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load from database service
      // For now, create some demo data
      _pieces = _createDemoData();
      _filterAndSortPieces();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading pieces: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterAndSortPieces() {
    _filteredPieces = _pieces.where((piece) {
      if (_searchQuery.isEmpty) return true;
      
      final query = _searchQuery.toLowerCase();
      return piece.title.toLowerCase().contains(query) ||
             piece.composer.toLowerCase().contains(query) ||
             (piece.keySignature?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Sort pieces
    switch (_sortOrder) {
      case SortOrder.priority:
        _filteredPieces.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
        break;
      case SortOrder.title:
        _filteredPieces.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOrder.composer:
        _filteredPieces.sort((a, b) => a.composer.compareTo(b.composer));
        break;
      case SortOrder.lastOpened:
        _filteredPieces.sort((a, b) {
          final aTime = a.lastOpened ?? DateTime(1970);
          final bTime = b.lastOpened ?? DateTime(1970);
          return bTime.compareTo(aTime);
        });
        break;
      case SortOrder.difficulty:
        _filteredPieces.sort((a, b) => b.difficulty.compareTo(a.difficulty));
        break;
    }
  }

  List<Piece> _createDemoData() {
    final now = DateTime.now();
    return [
      Piece(
        id: '1',
        title: 'Chopin Nocturne Op. 9 No. 2',
        composer: 'Frédéric Chopin',
        keySignature: 'E♭ major',
        difficulty: 4,
        concertDate: now.add(const Duration(days: 14)),
        lastOpened: now.subtract(const Duration(days: 1)),
        pdfFilePath: '/demo/chopin_nocturne.pdf',
        spots: [
          Spot(
            id: 's1',
            pieceId: '1',
            title: 'Measure 17-19 ornaments',
            description: 'Practice the grace notes slowly',
            pageNumber: 1,
            x: 0.15,
            y: 0.24,
            width: 0.3,
            height: 0.08,
            priority: SpotPriority.high,
            readinessLevel: ReadinessLevel.learning,
            color: SpotColor.red,
            createdAt: now.subtract(const Duration(days: 5)),
            updatedAt: now.subtract(const Duration(hours: 1)),
            nextDue: now.subtract(const Duration(hours: 12)),
            practiceCount: 8,
          ),
          Spot(
            id: 's2',
            pieceId: '1',
            title: 'Rubato passage',
            description: 'Work on expressive timing',
            pageNumber: 2,
            x: 0.2,
            y: 0.34,
            width: 0.25,
            height: 0.06,
            priority: SpotPriority.medium,
            readinessLevel: ReadinessLevel.review,
            color: SpotColor.yellow,
            createdAt: now.subtract(const Duration(days: 3)),
            updatedAt: now.subtract(const Duration(hours: 8)),
            nextDue: now.add(const Duration(hours: 6)),
            practiceCount: 5,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Piece(
        id: '2',
        title: 'Bach Invention No. 1',
        composer: 'Johann Sebastian Bach',
        keySignature: 'C major',
        difficulty: 3,
        lastOpened: now.subtract(const Duration(days: 3)),
        pdfFilePath: '/demo/bach_invention.pdf',
        spots: [
          Spot(
            id: 's3',
            pieceId: '2',
            title: 'Left hand independence',
            description: 'Practice hands separately first',
            pageNumber: 1,
            x: 0.12,
            y: 0.185,
            width: 0.28,
            height: 0.07,
            priority: SpotPriority.low,
            readinessLevel: ReadinessLevel.mastered,
            color: SpotColor.green,
            createdAt: now.subtract(const Duration(days: 7)),
            updatedAt: now.subtract(const Duration(days: 1)),
            nextDue: now.add(const Duration(days: 2)),
            practiceCount: 12,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      Piece(
        id: '3',
        title: 'Debussy Clair de Lune',
        composer: 'Claude Debussy',
        keySignature: 'D♭ major',
        difficulty: 5,
        concertDate: now.add(const Duration(days: 7)),
        lastOpened: now.subtract(const Duration(hours: 6)),
        pdfFilePath: '/demo/debussy_clair.pdf',
        spots: [
          Spot(
            id: 's4',
            pieceId: '3',
            title: 'Arpeggiated passage',
            description: 'Focus on smooth voice leading',
            pageNumber: 1,
            x: 0.28,
            y: 0.295,
            width: 0.32,
            height: 0.09,
            priority: SpotPriority.high,
            readinessLevel: ReadinessLevel.learning,
            color: SpotColor.red,
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(minutes: 30)),
            nextDue: now.subtract(const Duration(minutes: 30)),
            practiceCount: 3,
          ),
          Spot(
            id: 's5',
            pieceId: '3',
            title: 'Dynamic contrast',
            description: 'Careful pedaling for resonance',
            pageNumber: 2,
            x: 0.18,
            y: 0.2,
            width: 0.2,
            height: 0.05,
            priority: SpotPriority.medium,
            readinessLevel: ReadinessLevel.review,
            color: SpotColor.yellow,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(hours: 1)),
            nextDue: now.add(const Duration(hours: 4)),
            practiceCount: 6,
          ),
        ],
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterAndSortPieces();
    });
  }

  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }

  void _onSortOrderChanged(SortOrder order) {
    setState(() {
      _sortOrder = order;
      _filterAndSortPieces();
    });
  }

  void _onImportPDF() {
    showDialog(
      context: context,
      builder: (context) => const ImportPDFDialog(),
    ).then((result) {
      if (result == true) {
        _loadPieces(); // Refresh after import
      }
    });
  }

  void _onPieceSelected(Piece piece) {
    // Navigate to PDF Score Viewer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PDFScoreViewer(piece: piece),
      ),
    );
  }

  void _onQuickPractice() {
    // TODO: Navigate to Practice Session
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting smart practice session...'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSpots = _pieces.expand((piece) => piece.spots).toList();
    final urgentSpots = allSpots.where((spot) => spot.isDue).toList();
    final criticalSpots = allSpots.where((spot) => spot.color == SpotColor.red).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search and controls
            LibraryHeader(
              searchQuery: _searchQuery,
              viewMode: _viewMode,
              sortOrder: _sortOrder,
              onSearchChanged: _onSearchChanged,
              onViewModeChanged: _onViewModeChanged,
              onSortOrderChanged: _onSortOrderChanged,
              onImport: _onImportPDF,
            ),

            // Practice status bar
            if (urgentSpots.isNotEmpty)
              PracticeStatusBar(
                urgentSpots: urgentSpots,
                criticalSpots: criticalSpots,
                onPracticeNow: _onQuickPractice,
              ),

            // Quick action chips
            QuickActionChips(
              urgentSpots: urgentSpots,
              criticalSpots: criticalSpots,
              onSmartPractice: _onQuickPractice,
              onCriticalSpots: () {
                // TODO: Start critical spots session
              },
              onWarmup: () {
                // TODO: Start warmup session
              },
            ),

            // Main content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading your music library...'),
                        ],
                      ),
                    )
                  : _filteredPieces.isEmpty
                      ? _buildEmptyState()
                      : _buildPiecesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty 
                  ? 'No music sheets yet'
                  : 'No sheets match your search',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Import your first PDF to get started'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _onImportPDF,
                icon: const Icon(Icons.add),
                label: const Text('Import PDF'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPiecesList() {
    if (_viewMode == ViewMode.grid) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate safe crossAxisCount based on available width
          final availableWidth = constraints.maxWidth - 32; // Account for padding
          final minCardWidth = 280.0; // Minimum card width
          final crossAxisCount = (availableWidth / minCardWidth).floor().clamp(1, 3);
          
          return Padding(
            padding: const EdgeInsets.all(16),
            child: MasonryGridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              itemCount: _filteredPieces.length,
              itemBuilder: (context, index) {
                return PieceCard(
                  piece: _filteredPieces[index],
                  viewMode: ViewMode.grid,
                  onTap: () => _onPieceSelected(_filteredPieces[index]),
                );
              },
            ),
          );
        },
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredPieces.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PieceCard(
              piece: _filteredPieces[index],
              viewMode: ViewMode.list,
              onTap: () => _onPieceSelected(_filteredPieces[index]),
            ),
          );
        },
      );
    }
  }
}

/// View mode for piece display
enum ViewMode {
  grid,
  list,
}

/// Sort order options
enum SortOrder {
  priority,
  title,
  composer,
  lastOpened,
  difficulty,
}
