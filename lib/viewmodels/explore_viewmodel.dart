import 'package:flutter/material.dart';
import 'package:plansync/data/explore_repository.dart';
import 'package:plansync/models/activity.dart';

class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel(this._userId);

  final String _userId;
  final _repository = ExploreRepository();

  static const allTags = 'All';
  static const whenOptions = ['Week', 'Month', 'Later'];
  static const priceOptions = ['Free', r'$', r'$$', r'$$$'];
  static const ratingOptions = ['4+', '3+', 'All'];

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
  List<Activity> _activities = [];
  List<Activity> filteredActivities = [];

  Set<String> recommendedIds = {};
  bool isLoading = false;
  String? errorMessage;

  bool isRecommended(ExplorePlan item) => recommendedIds.contains(item.plan.id);

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getPlans(),
        _repository.getActivities(),
        _repository.recommendedPlanIds(_userId),
      ]);
      final plans = results[0] as List<ExplorePlan>;
      _activities = results[1] as List<Activity>;
      final recommended = results[2] as List<String>;

      recommendedIds = recommended.toSet();
      _plans = _recommendedFirst(plans, recommended);
      tagOptions = [allTags, ..._tagsByPopularity()];
      if (!tagOptions.contains(selectedTag)) selectedTag = allTags;
      filteredPlans = _filterPlans();
      filteredActivities = _filterActivities();
    } catch (_) {
      errorMessage = 'Could not load plans. Try again.';
    }

    isLoading = false;
    notifyListeners();
  }

  List<ExplorePlan> _recommendedFirst(
    List<ExplorePlan> plans,
    List<String> recommended,
  ) {
    final rank = {
      for (var i = 0; i < recommended.length; i++) recommended[i]: i,
    };
    final top = plans.where((p) => rank.containsKey(p.plan.id)).toList();
    top.sort((a, b) => rank[a.plan.id]!.compareTo(rank[b.plan.id]!));
    final rest = plans.where((p) => !rank.containsKey(p.plan.id));
    return [...top, ...rest];
  }

  void onSearchQueryChange(String query) {
    searchQuery = query;
    _applyFilters();
  }

  void onTagSelect(String tag) {
    selectedTag = tag;
    _applyFilters();
  }

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
    filteredActivities = _filterActivities();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<String> _tagsByPopularity() {
    final counts = <String, int>{};
    final tagLists = [
      for (final item in _plans) item.plan.tags,
      for (final activity in _activities) activity.tags,
    ];
    for (final tags in tagLists) {
      for (final tag in tags.map((t) => t.toLowerCase()).toSet()) {
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

  List<Activity> _filterActivities() {
    if (selectedWhen != null || selectedRating != 'All') return [];
    final query = searchQuery.toLowerCase();
    return _activities.where((activity) {
      final tags = activity.tags.map((t) => t.toLowerCase());
      final matchesSearch =
          query.isEmpty ||
          activity.name.toLowerCase().contains(query) ||
          tags.any((t) => t.contains(query));
      final matchesTag = selectedTag == allTags || tags.contains(selectedTag);
      return matchesSearch &&
          matchesTag &&
          _matchesPrice(activity.expectedPrice);
    }).toList();
  }

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
