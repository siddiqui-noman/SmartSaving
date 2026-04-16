import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';

final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(() {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    ref.watch(currentUserProvider); // Invalidate history dynamically when user logs out/in
    return storageService.getRecentSearches();
  }

  Future<void> addSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    
    final currentSearches = List<String>.from(state);
    currentSearches.remove(q); // remove old instance
    currentSearches.insert(0, q); // put exactly at the top
    
    if (currentSearches.length > 10) {
      currentSearches.removeLast(); // keep only 10
    }
    
    state = currentSearches;
    await storageService.saveRecentSearches(currentSearches);
  }

  Future<void> clearHistory() async {
    state = [];
    await storageService.saveRecentSearches([]);
  }

  Future<void> removeSearch(String query) async {
    final currentSearches = List<String>.from(state);
    currentSearches.remove(query);
    state = currentSearches;
    await storageService.saveRecentSearches(currentSearches);
  }
}
