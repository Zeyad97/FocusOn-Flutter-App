import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../library_screen.dart';

/// Header component with search, view mode, and sort controls
class LibraryHeader extends StatelessWidget {
  final String searchQuery;
  final ViewMode viewMode;
  final SortOrder sortOrder;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ViewMode> onViewModeChanged;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final VoidCallback onImport;

  const LibraryHeader({
    super.key,
    required this.searchQuery,
    required this.viewMode,
    required this.sortOrder,
    required this.onSearchChanged,
    required this.onViewModeChanged,
    required this.onSortOrderChanged,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Title and import button
          Row(
            children: [
              Text(
                'Music Library',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onImport,
                icon: const Icon(Icons.add),
                tooltip: 'Import PDF',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Search bar
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by title, composer, or key...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () => onSearchChanged(''),
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.textSecondary.withOpacity(0.1),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Controls row
          Row(
            children: [
              // Sort dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<SortOrder>(
                  value: sortOrder,
                  onChanged: (value) {
                    if (value != null) onSortOrderChanged(value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SortOrder.priority,
                      child: Text('Priority', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: SortOrder.title,
                      child: Text('Title', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: SortOrder.composer,
                      child: Text('Composer', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: SortOrder.lastOpened,
                      child: Text('Recent', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: SortOrder.difficulty,
                      child: Text('Difficulty', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // View mode toggle
              SegmentedButton<ViewMode>(
                selected: {viewMode},
                onSelectionChanged: (selection) {
                  onViewModeChanged(selection.first);
                },
                segments: const [
                  ButtonSegment(
                    value: ViewMode.grid,
                    icon: Icon(Icons.grid_view, size: 18),
                  ),
                  ButtonSegment(
                    value: ViewMode.list,
                    icon: Icon(Icons.list, size: 18),
                  ),
                ],
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
