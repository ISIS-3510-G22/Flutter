import 'package:flutter/material.dart';
import 'package:plansync/data/explore_repository.dart';

class ExploreViewModel extends ChangeNotifier {
  final _repository = ExploreRepository();

  static const allTags = 'All';
  static const whenOptions = ['Week', 'Month', 'Later'];
  static const priceOptions = ['Free', r'$', r'$$', r'$$$'];
  static const ratingOptions = ['4+', '3+', 'All'];

  // Upper limit (in pesos) of the estimated plan cost for each price level.
  static const _cheapMax = 50000.0;
  static const _midMax = 150000.0;

  final searchController = TextEditingController();

  String searchQuery = '';
  String selectedTag = allTags;
  List<String> tagOptions = [allTags];
  String? selectedWhen;
  String? selectedPrice;
  String selectedRating = 'All';

  List<ExplorePlan> _plans = [];
  List<ExplorePlan> filteredPlans = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadPlans() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _plans = await _repository.getPlans();
      tagOptions = [allTags, ..._tagsByPopularity()];
      if (!tagOptions.contains(selectedTag)) selectedTag = allTags;
      filteredPlans = _filterPlans();
    } catch (_) {
      errorMessage = 'Could not load plans. Try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  void onSearchQueryChange(String query) {
    searchQuery = query;
    _applyFilters();
  }

  void onTagSelect(String tag) {
    selectedTag = tag;
    _applyFilters();
  }

  /// Tapping the selected option again clears the filter.
  void onWhenSelect(String when) {
    if (selectedWhen == when) {
      selectedWhen = null;
    } else {
      selectedWhen = when;
    }
    _applyFilters();
  }

  void onPriceSelect(String price) {
    if (selectedPrice == price) {
      selectedPrice = null;
    } else {
      selectedPrice = price;
    }
    _applyFilters();
  }

  void onRatingSelect(String rating) {
    if (selectedRating == rating) {
      selectedRating = 'All';
    } else {
      selectedRating = rating;
    }
    _applyFilters();
  }

  void _applyFilters() {
    filteredPlans = _filterPlans();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Tags of the loaded plans, most common first.
  List<String> _tagsByPopularity() {
    final counts = <String, int>{};
    for (final item in _plans) {
      for (final tag in item.plan.tags.map((t) => t.toLowerCase()).toSet()) {
        final current = counts[tag];
        if (current == null) {
          counts[tag] = 1;
        } else {
          counts[tag] = current + 1;
        }
      }
    }
    final tags = counts.keys.toList();
    tags.sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      return a.compareTo(b);
    });
    return tags;
  }

  List<ExplorePlan> _filterPlans() {
    final query = searchQuery.toLowerCase();
    return _plans.where((item) {
      final plan = item.plan;
      final tags = plan.tags.map((t) => t.toLowerCase());
      final matchesSearch =
          query.isEmpty ||
          plan.name.toLowerCase().contains(query) ||
          tags.any((t) => t.contains(query));
      final matchesTag = selectedTag == allTags || tags.contains(selectedTag);

      return matchesSearch &&
          matchesTag &&
          _matchesWhen(plan.date) &&
          _matchesPrice(item.totalCost) &&
          _matchesRating(item.rating);
    }).toList();
  }

  /// Explore only lists upcoming plans, so these ranges start today.
  bool _matchesWhen(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(Duration(days: 8 - today.weekday));
    final endOfMonth = DateTime(today.year, today.month + 1);
    switch (selectedWhen) {
      case null:
        return true;
      case 'Week':
        return date.isBefore(endOfWeek);
      case 'Month':
        return date.isBefore(endOfMonth);
      case 'Later':
        return !date.isBefore(endOfMonth);
    }
    return true;
  }

  bool _matchesPrice(double cost) {
    switch (selectedPrice) {
      case null:
        return true;
      case 'Free':
        return cost == 0;
      case r'$':
        return cost > 0 && cost <= _cheapMax;
      case r'$$':
        return cost > _cheapMax && cost <= _midMax;
      case r'$$$':
        return cost > _midMax;
    }
    return true;
  }

  bool _matchesRating(double? rating) {
    if (selectedRating == 'All') return true;
    if (rating == null) return false;
    if (selectedRating == '4+') return rating >= 4;
    if (selectedRating == '3+') return rating >= 3;
    return true;
  }
}
