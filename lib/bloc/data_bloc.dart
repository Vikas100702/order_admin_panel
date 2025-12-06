import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/repositories/data_repository.dart';
import '../models/filter_model.dart';

// Events
abstract class DataEvent {}
class LoadDataEvent extends DataEvent { final bool forceRefresh; LoadDataEvent({this.forceRefresh = false}); }
class ApplyFilterEvent extends DataEvent { final FilterCriteria criteria; ApplyFilterEvent(this.criteria); }
class UploadFileEvent extends DataEvent { final List<int> bytes; final String name; UploadFileEvent(this.bytes, this.name); }

// States
abstract class DataState {}
class DataInitial extends DataState {}
class DataLoading extends DataState {}
class DataError extends DataState { final String message; DataError(this.message); }
class UploadSuccess extends DataState { final String message; UploadSuccess(this.message); }

class DataLoaded extends DataState {
  final List<dynamic> filteredOrders;
  final FilterCriteria activeFilters;

  // Metadata for Dropdowns (Extracted from Master List)
  final List<String> allOrderStates;
  final List<String> allCities;
  final List<String> allGeoStates;
  final double maxInvoiceAmount;

  DataLoaded({
    required this.filteredOrders,
    required this.activeFilters,
    required this.allOrderStates,
    required this.allCities,
    required this.allGeoStates,
    required this.maxInvoiceAmount,
  });
}

class DataBloc extends Bloc<DataEvent, DataState> {
  final DataRepository dataRepository;

  // 🚀 MASTER CACHE (Holds raw data)
  List<dynamic> _masterList = [];

  DataBloc({required this.dataRepository}) : super(DataInitial()) {

    // 1. Fetch Data
    on<LoadDataEvent>((event, emit) async {
      emit(DataLoading());
      try {
        if (_masterList.isEmpty || event.forceRefresh) {
          _masterList = await dataRepository.getOrders('');
        }
        _emitLoadedState(emit, FilterCriteria());
      } catch (e) {
        emit(DataError(e.toString()));
      }
    });

    // 2. Filter Data
    on<ApplyFilterEvent>((event, emit) {
      _emitLoadedState(emit, event.criteria);
    });

    // 3. Upload Logic
    on<UploadFileEvent>((event, emit) async {
      try {
        await dataRepository.uploadCsv(event.bytes, event.name);
        emit(UploadSuccess("File uploaded successfully"));
        add(LoadDataEvent(forceRefresh: true));
      } catch (e) {
        emit(DataError(e.toString()));
      }
    });
  }

  void _emitLoadedState(Emitter<DataState> emit, FilterCriteria criteria) {
    // 1. Extract Dropdown Options from Master Data (Unique Values)
    final states = _masterList.map((e) => e['Order State']?.toString() ?? '').toSet().toList()..remove('');
    final cities = _masterList.map((e) => e['City']?.toString() ?? '').toSet().toList()..remove('');
    final geoStates = _masterList.map((e) => e['State']?.toString() ?? '').toSet().toList()..remove('');

    // Calculate Max Amount for Slider
    double maxAmt = 0;
    for(var item in _masterList) {
      double val = double.tryParse(item['Invoice Amount']?.toString() ?? '0') ?? 0;
      if(val > maxAmt) maxAmt = val;
    }

    // 2. FILTERING LOGIC
    final filtered = _masterList.where((row) {
      // A. Global Search (Matches ANY value in the row)
      if (criteria.searchQuery.isNotEmpty) {
        final q = criteria.searchQuery.toLowerCase();
        bool matchFound = false;

        // Iterate through all values in the row map
        if (row is Map) {
          for (final value in row.values) {
            // Convert value to string, lowercase it, and check for containment
            if (value != null && value.toString().toLowerCase().contains(q)) {
              matchFound = true;
              break; // Stop checking other fields if match found
            }
          }
        }

        if (!matchFound) return false;
      }

      // B. Dropdowns
      if (criteria.selectedStates.isNotEmpty && !criteria.selectedStates.contains(row['Order State'])) return false;
      if (criteria.selectedCities.isNotEmpty && !criteria.selectedCities.contains(row['City'])) return false;
      if (criteria.selectedGeoStates.isNotEmpty && !criteria.selectedGeoStates.contains(row['State'])) return false;

      // C. Numeric Range
      if (criteria.amountRange != null) {
        final amt = double.tryParse(row['Invoice Amount']?.toString() ?? '0') ?? 0;
        if (amt < criteria.amountRange!.start || amt > criteria.amountRange!.end) return false;
      }

      // D. Date Filters
      if (!_checkDate(row['Ordered On'], criteria.orderedDateRange)) return false;
      if (!_checkDate(row['Invoice Date (mm/dd/yy)'], criteria.invoiceDateRange)) return false;

      // E. Boolean Filters
      if (criteria.readyToMake != null) {
        final val = row['Ready to Make']?.toString().toLowerCase() == 'true' || row['Ready to Make']?.toString().toLowerCase() == 'yes';
        if (val != criteria.readyToMake) return false;
      }

      return true;
    }).toList();

    emit(DataLoaded(
        filteredOrders: filtered,
        activeFilters: criteria,
        allOrderStates: states,
        allCities: cities,
        allGeoStates: geoStates,
        maxInvoiceAmount: maxAmt
    ));
  }

  bool _checkDate(String? dateStr, DateTimeRange? range) {
    if (range == null || dateStr == null) return true;
    try {
      // Handle "mm/dd/yy" or standard format
      final date = DateTime.tryParse(dateStr);
      if (date == null) return true; // Skip if invalid date
      return date.isAfter(range.start.subtract(Duration(days:1))) &&
          date.isBefore(range.end.add(Duration(days:1)));
    } catch (e) {
      return true;
    }
  }
}