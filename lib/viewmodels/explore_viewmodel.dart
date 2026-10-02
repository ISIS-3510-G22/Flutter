import 'package:flutter/material.dart';
import 'package:plansync/data/explore_repository.dart';

class ExploreViewModel extends ChangeNotifier {
  final _repository = ExploreRepository();

  static const categoryOptions = [
    'All',
    'Weekend Getaways',
    'Food & Drink',
    'Outdoors',
    'Culture',
  ];
  static const planTypeOptions = ['Solo', 'Couple', 'Group', 'Family'];
  static const priceOptions = ['Free', r'$', r'$$', r'$$$'];
  static const ratingOptions = ['4+', '3+', 'All'];

  final searchController = TextEditingController();

  String searchQuery = '';
  String selectedCategory = 'All';
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

  void onCategorySelect(String category) {
    selectedCategory = category;
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

  List<ExplorePlan> _filterPlans() {
    return _plans.where((item) {
      final plan = item.plan;
      final matchesSearch =
          searchQuery.isEmpty ||
          plan.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory =
          selectedCategory == 'All' ||
          plan.tags.any(
            (t) => t.toLowerCase() == selectedCategory.toLowerCase(),
          );

      return matchesSearch && matchesCategory;
    }).toList();
  }
}
