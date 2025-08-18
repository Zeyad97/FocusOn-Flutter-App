class PDFDocument {
  final String id;
  final String title;
  final String filePath;
  final String category;
  final List<int> bookmarks;
  final bool isFavorite;
  final DateTime dateAdded;
  final DateTime lastOpened;

  PDFDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.category,
    this.bookmarks = const [],
    this.isFavorite = false,
    DateTime? dateAdded,
    DateTime? lastOpened,
  })  : dateAdded = dateAdded ?? DateTime.now(),
        lastOpened = lastOpened ?? DateTime.now();

  PDFDocument copyWith({
    String? id,
    String? title,
    String? filePath,
    String? category,
    List<int>? bookmarks,
    bool? isFavorite,
    DateTime? dateAdded,
    DateTime? lastOpened,
  }) {
    return PDFDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      category: category ?? this.category,
      bookmarks: bookmarks ?? this.bookmarks,
      isFavorite: isFavorite ?? this.isFavorite,
      dateAdded: dateAdded ?? this.dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filePath': filePath,
      'category': category,
      'bookmarks': bookmarks,
      'isFavorite': isFavorite,
      'dateAdded': dateAdded.millisecondsSinceEpoch,
      'lastOpened': lastOpened.millisecondsSinceEpoch,
    };
  }

  factory PDFDocument.fromJson(Map<String, dynamic> json) {
    return PDFDocument(
      id: json['id'],
      title: json['title'],
      filePath: json['filePath'],
      category: json['category'],
      bookmarks: List<int>.from(json['bookmarks'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(json['dateAdded']),
      lastOpened: DateTime.fromMillisecondsSinceEpoch(json['lastOpened']),
    );
  }
}
