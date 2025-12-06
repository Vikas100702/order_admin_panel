import 'package:flutter/material.dart';

class FilterCriteria {
  // Global Search (Matches IDs, Names, SKU, Product)
  String searchQuery;

  // Date Ranges
  DateTimeRange? orderedDateRange;
  DateTimeRange? invoiceDateRange;
  DateTimeRange? dispatchDateRange;

  // Categorical Filters (Multi-select)
  List<String> selectedStates;      // Order State (e.g. Shipped)
  List<String> selectedOrderTypes;  // Order Type
  List<String> selectedCities;      // City
  List<String> selectedGeoStates;   // State (Location)

  // Boolean/Status Flags
  bool? readyToMake;    // Null = All, True = Yes, False = No
  bool? withAttachment; // Null = All, True = Yes, False = No

  // Numeric Ranges
  RangeValues? amountRange; // Invoice Amount

  FilterCriteria({
    this.searchQuery = '',
    this.orderedDateRange,
    this.invoiceDateRange,
    this.dispatchDateRange,
    this.selectedStates = const [],
    this.selectedOrderTypes = const [],
    this.selectedCities = const [],
    this.selectedGeoStates = const [],
    this.readyToMake,
    this.withAttachment,
    this.amountRange,
  });

  // Helper to check if any filter is active
  bool get hasFilters =>
      searchQuery.isNotEmpty ||
          orderedDateRange != null ||
          invoiceDateRange != null ||
          dispatchDateRange != null ||
          selectedStates.isNotEmpty ||
          selectedOrderTypes.isNotEmpty ||
          selectedCities.isNotEmpty ||
          selectedGeoStates.isNotEmpty ||
          readyToMake != null ||
          withAttachment != null ||
          amountRange != null;

  // CopyWith for immutability (crucial for Bloc)
  FilterCriteria copyWith({
    String? searchQuery,
    DateTimeRange? orderedDateRange,
    DateTimeRange? invoiceDateRange,
    DateTimeRange? dispatchDateRange,
    List<String>? selectedStates,
    List<String>? selectedOrderTypes,
    List<String>? selectedCities,
    List<String>? selectedGeoStates,
    bool? readyToMake,
    bool? withAttachment,
    RangeValues? amountRange,
  }) {
    return FilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      orderedDateRange: orderedDateRange ?? this.orderedDateRange,
      invoiceDateRange: invoiceDateRange ?? this.invoiceDateRange,
      dispatchDateRange: dispatchDateRange ?? this.dispatchDateRange,
      selectedStates: selectedStates ?? this.selectedStates,
      selectedOrderTypes: selectedOrderTypes ?? this.selectedOrderTypes,
      selectedCities: selectedCities ?? this.selectedCities,
      selectedGeoStates: selectedGeoStates ?? this.selectedGeoStates,
      readyToMake: readyToMake ?? this.readyToMake,
      withAttachment: withAttachment ?? this.withAttachment,
      amountRange: amountRange ?? this.amountRange,
    );
  }
}