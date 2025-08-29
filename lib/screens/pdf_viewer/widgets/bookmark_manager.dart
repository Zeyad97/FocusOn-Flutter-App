import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/bookmark.dart';
import '../../../models/piece.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';

/// Comprehensive bookmark management widget for PDF viewer
class BookmarkManager extends ConsumerStatefulWidget {
  final Piece piece;
  final int currentPage;
  final Function(int) onNavigateToPage;

  const BookmarkManager({
    super.key,
    required this.piece,
    required this.currentPage,
    required this.onNavigateToPage,
  });

  @override
  ConsumerState<BookmarkManager> createState() => _BookmarkManagerState();
}

class _BookmarkManagerState extends ConsumerState<BookmarkManager> {
  List<Bookmark> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();
      _bookmarks = await dbService.getBookmarksForPiece(widget.piece.id);
    } catch (e) {
      print('Error loading bookmarks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBookmark() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => _BookmarkCreationDialog(
        currentPage: widget.currentPage,
      ),
    );

    if (result != null) {
      final bookmark = Bookmark(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        pdfId: widget.piece.id,
        pageNumber: widget.currentPage,
        note: result['title'] ?? '',
        createdAt: DateTime.now(),
      );

      try {
        final dbService = DatabaseService();
        await dbService.insertBookmark(bookmark);
        await _loadBookmarks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bookmark added successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding bookmark: $e'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteBookmark(Bookmark bookmark) async {
    try {
      final dbService = DatabaseService();
      await dbService.deleteBookmark(bookmark.id);
      await _loadBookmarks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bookmark deleted'),
            backgroundColor: AppColors.primaryPurple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting bookmark: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.bookmark, color: AppColors.primaryPurple),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bookmarks',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_bookmarks.length} bookmark${_bookmarks.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                FloatingActionButton.small(
                  onPressed: _addBookmark,
                  backgroundColor: AppColors.primaryPurple,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // Bookmarks list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _bookmarks.isEmpty
                    ? _buildEmptyState()
                    : _buildBookmarksList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add bookmarks to important pages for quick access',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addBookmark,
              icon: Icon(Icons.add),
              label: Text('Add First Bookmark'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList() {
    final sortedBookmarks = List<Bookmark>.from(_bookmarks)
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: sortedBookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = sortedBookmarks[index];
        final isCurrentPage = bookmark.pageNumber == widget.currentPage;

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: isCurrentPage ? 4 : 2,
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrentPage 
                    ? AppColors.primaryPurple 
                    : AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'P${bookmark.pageNumber}',
                  style: TextStyle(
                    color: isCurrentPage ? Colors.white : AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            title: Text(
              bookmark.note.isNotEmpty ? bookmark.note : 'Page ${bookmark.pageNumber}',
              style: TextStyle(
                fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            subtitle: bookmark.note.isNotEmpty
                ? Text(
                    'Page ${bookmark.pageNumber}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCurrentPage)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'delete':
                        _showDeleteConfirmation(bookmark);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.errorRed),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () {
              widget.onNavigateToPage(bookmark.pageNumber);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Bookmark'),
        content: Text('Are you sure you want to delete the bookmark "${bookmark.note.isNotEmpty ? bookmark.note : 'Page ${bookmark.pageNumber}'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBookmark(bookmark);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for creating new bookmarks
class _BookmarkCreationDialog extends StatefulWidget {
  final int currentPage;

  const _BookmarkCreationDialog({
    required this.currentPage,
  });

  @override
  State<_BookmarkCreationDialog> createState() => _BookmarkCreationDialogState();
}

class _BookmarkCreationDialogState extends State<_BookmarkCreationDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.bookmark_add, color: AppColors.primaryPurple),
          SizedBox(width: 12),
          Text('Add Bookmark'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: AppColors.primaryPurple),
                  SizedBox(width: 8),
                  Text(
                    'Page ${widget.currentPage}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Bookmark Title*',
                hintText: 'e.g., "Difficult passage", "Practice section"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              autofocus: true,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Additional notes about this bookmark',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () {
            if (!_isProcessing) {
              setState(() => _isProcessing = true);
              Navigator.pop(context);
            }
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : () {
            if (!_isProcessing && _formKey.currentState!.validate()) {
              setState(() => _isProcessing = true);
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'description': _descriptionController.text.trim().isEmpty 
                    ? null 
                    : _descriptionController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          child: Text('Add Bookmark'),
        ),
      ],
    );
  }
}
