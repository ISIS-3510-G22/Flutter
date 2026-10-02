import 'package:flutter/material.dart';
import 'package:plansync/data/explore_repository.dart';

class ExploreViewModel extends ChangeNotifier {
  final _repository = ExploreRepository();

  static const allTags = 'All';
  static const planTypeOptions = ['Solo', 'Couple', 'Group', 'Family'];
  static const priceOptions = ['Free', r'$', r'$$', r'$$$'];
  static const ratingOptions = ['4+', '3+', 'All'];

  final searchController = TextEditingController();

  String searchQuery = '';
  String selectedTag = allTags;
  List<String> tagOptions = [allTags];
  String selectedPlanType = 'Group';
  String selectedPrice = r'$$';
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

  void onPlanTypeSelect(String planType) {
    selectedPlanType = planType;
    _applyFilters();
  }

  void onPriceSelect(String price) {
    selectedPrice = price;
    _applyFilters();
  }

  void onRatingSelect(String rating) {
    selectedRating = rating;
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

      return matchesSearch && matchesTag;
    }).toList();
  }
}
