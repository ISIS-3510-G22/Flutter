import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plansync/model/data/connectivity_repository.dart';
import 'package:plansync/model/data/explore_repository.dart';
import 'package:plansync/model/models/activity.dart';
import 'package:plansync/model/models/explore_filters.dart';
import 'package:plansync/model/models/explore_plan.dart';
import 'package:plansync/model/models/explore_snapshot.dart';

class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel(this._userId) {
    _connectivitySub = ConnectivityRepository.instance.changes.listen((online) {
      if (online) _loadSnapshot();
    });
    _load();
  }

  final String _userId;
  final _repository = ExploreRepository();
  late final StreamSubscription<bool> _connectivitySub;
  StreamSubscription<ExploreSnapshot>? _snapshotSub;

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
  bool isLoading = true;

  /// False until a snapshot arrives, from the file or the server. Offline
  /// and still false means Explore was never loaded on this phone.
  bool hasSnapshot = false;

  bool get hasPlans => _plans.isNotEmpty;

  bool isRecommended(ExplorePlan item) => recommendedIds.contains(item.plan.id);

  Future<void> _load() async {
    _restoreFilters(await _repository.savedFilters());
    _loadSnapshot();
  }

  void _restoreFilters(ExploreFilters saved) {
    selectedTag = saved.tag ?? allTags;
    if (whenOptions.contains(saved.when)) selectedWhen = saved.when;
    if (priceOptions.contains(saved.price)) selectedPrice = saved.price;
    if (ratingOptions.contains(saved.rating)) selectedRating = saved.rating!;
  }

  /// Pull to refresh: the same load as on open (saved file, then server).
  /// Completes when the load finishes; offline that's right after the file.
  Future<void> refresh() => _loadSnapshot();

  // Shared by every load that overlaps: a load cancelled by a newer one
  // never reaches `onDone`, so the newer one completes the same future and
  // the refresh spinner never hangs.
  Completer<void>? _loadDone;

  Future<void> _loadSnapshot() {
    final done = _loadDone ??= Completer<void>();
    isLoading = true;
    notifyListeners();
    _snapshotSub?.cancel();
    _snapshotSub = _repository
        .snapshot(_userId)
        .listen(
          _show,
          onDone: () {
            isLoading = false;
            _loadDone = null;
            done.complete();
            notifyListeners();
          },
        );
    return done.future;
  }

  void _show(ExploreSnapshot snapshot) {
    hasSnapshot = true;
    _activities = snapshot.activities;
    recommendedIds = snapshot.recommendedIds.toSet();
    _plans = _recommendedFirst(snapshot.plans, snapshot.recommendedIds);
    tagOptions = [allTags, ..._tagsByPopularity()];
    if (!tagOptions.contains(selectedTag)) selectedTag = allTags;
    _applyFilters();
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
    _saveFilters();
  }

  void onWhenSelect(String when) {
    if (selectedWhen == when) {
      selectedWhen = null;
    } else {
      selectedWhen = when;
    }
    _applyFilters();
    _saveFilters();
  }

  void onPriceSelect(String price) {
    if (selectedPrice == price) {
      selectedPrice = null;
    } else {
      selectedPrice = price;
    }
    _applyFilters();
    _saveFilters();
  }

  void onRatingSelect(String rating) {
    if (selectedRating == rating) {
      selectedRating = 'All';
    } else {
      selectedRating = rating;
    }
    _applyFilters();
    _saveFilters();
  }

  void _applyFilters() {
    filteredPlans = _filterPlans();
    filteredActivities = _filterActivities();
    notifyListeners();
  }

  void _saveFilters() {
    unawaited(
      _repository.saveFilters(
        ExploreFilters(
          tag: selectedTag,
          when: selectedWhen,
          price: selectedPrice,
          rating: selectedRating,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _snapshotSub?.cancel();
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
