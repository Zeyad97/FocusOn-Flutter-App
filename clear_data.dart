import 'package:shared_preferences/shared_preferences.dart';

/// Utility script to clear all app data from SharedPreferences
/// Run this with: dart run clear_data.dart
Future<void> main() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // List all keys before clearing
    final keys = prefs.getKeys();
    print('Found ${keys.length} keys in SharedPreferences:');
    for (final key in keys) {
      print('  - $key');
    }
    
    // Clear all data
    await prefs.clear();
    
    print('\n✅ All SharedPreferences data cleared!');
    print('   - Projects: cleared');
    print('   - Pieces: cleared');  
    print('   - Spots: cleared');
    print('   - Practice sessions: cleared');
    print('   - All other app data: cleared');
    
    print('\nRestart the app to see empty state.');
    
  } catch (e) {
    print('❌ Error clearing data: $e');
  }
}
