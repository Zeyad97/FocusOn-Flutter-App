import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_document.dart';
import '../models/bookmark.dart';

class StorageService {
  static const String _pdfsKey = 'pdfs';
  static const String _bookmarksKey = 'bookmarks';
  static const String _categoriesKey = 'categories';

  // PDF Document operations
  Future<List<PDFDocument>> getAllPDFs() async {
    final prefs = await SharedPreferences.getInstance();
    final pdfsJson = prefs.getStringList(_pdfsKey) ?? [];
    return pdfsJson.map((json) => PDFDocument.fromJson(jsonDecode(json))).toList();
  }

  Future<void> savePDF(PDFDocument pdf) async {
    final prefs = await SharedPreferences.getInstance();
    final pdfs = await getAllPDFs();
    
    // Remove existing PDF with same ID if it exists
    pdfs.removeWhere((p) => p.id == pdf.id);
    pdfs.add(pdf);
    
    final pdfsJson = pdfs.map((pdf) => jsonEncode(pdf.toJson())).toList();
    await prefs.setStringList(_pdfsKey, pdfsJson);
  }

  Future<void> deletePDF(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final pdfs = await getAllPDFs();
    pdfs.removeWhere((pdf) => pdf.id == id);
    
    final pdfsJson = pdfs.map((pdf) => jsonEncode(pdf.toJson())).toList();
    await prefs.setStringList(_pdfsKey, pdfsJson);
    
    // Also delete related bookmarks
    await deleteBookmarksForPDF(id);
  }

  Future<List<PDFDocument>> getFavoritePDFs() async {
    final pdfs = await getAllPDFs();
    return pdfs.where((pdf) => pdf.isFavorite).toList();
  }

  Future<List<PDFDocument>> getPDFsByCategory(String category) async {
    final pdfs = await getAllPDFs();
    return pdfs.where((pdf) => pdf.category == category).toList();
  }

  // Bookmark operations
  Future<List<Bookmark>> getAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = prefs.getStringList(_bookmarksKey) ?? [];
    return bookmarksJson.map((json) => Bookmark.fromJson(jsonDecode(json))).toList();
  }

  Future<void> saveBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getAllBookmarks();
    
    // Remove existing bookmark with same ID if it exists
    bookmarks.removeWhere((b) => b.id == bookmark.id);
    bookmarks.add(bookmark);
    
    final bookmarksJson = bookmarks.map((bookmark) => jsonEncode(bookmark.toJson())).toList();
    await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }

  Future<void> deleteBookmark(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarks = await getAllBookmarks();
    bookmarks.removeWhere((bookmark) => bookmark.id == id);
    
    final bookmarksJson = bookmarks.map((bookmark) => jsonEncode(bookmark.toJson())).toList();
    await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }

  Future<void> deleteBookmarksForPDF(String pdfId) async {
    final bookmarks = await getAllBookmarks();
    bookmarks.removeWhere((bookmark) => bookmark.pdfId == pdfId);
    
    final prefs = await SharedPreferences.getInstance();
    final bookmarksJson = bookmarks.map((bookmark) => jsonEncode(bookmark.toJson())).toList();
    await prefs.setStringList(_bookmarksKey, bookmarksJson);
  }

  Future<List<Bookmark>> getBookmarksForPDF(String pdfId) async {
    final bookmarks = await getAllBookmarks();
    return bookmarks.where((bookmark) => bookmark.pdfId == pdfId).toList();
  }

  // Categories operations
  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_categoriesKey) ?? ['Classical', 'Jazz', 'Pop', 'Folk', 'Other'];
  }

  Future<void> addCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    if (!categories.contains(category)) {
      categories.add(category);
      await prefs.setStringList(_categoriesKey, categories);
    }
  }

  Future<void> deleteCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    categories.remove(category);
    await prefs.setStringList(_categoriesKey, categories);
  }
}
