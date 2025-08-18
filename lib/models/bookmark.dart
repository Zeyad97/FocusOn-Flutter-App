class Bookmark {
  final String id;
  final String pdfId;
  final int pageNumber;
  final String note;
  final DateTime createdAt;

  Bookmark({
    required this.id,
    required this.pdfId,
    required this.pageNumber,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pdfId': pdfId,
      'pageNumber': pageNumber,
      'note': note,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'],
      pdfId: json['pdfId'],
      pageNumber: json['pageNumber'],
      note: json['note'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
    );
  }
}
