import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/bloc/data_bloc.dart';
import 'package:order_admin_panel/core/app_theme.dart';
import 'package:order_admin_panel/models/filter_model.dart';

class FilterDrawer extends StatefulWidget {
  const FilterDrawer({Key? key}) : super(key: key);

  @override
  _FilterDrawerState createState() => _FilterDrawerState();
}

class _FilterDrawerState extends State<FilterDrawer> {
  late FilterCriteria _criteria;

  // Stores search text for different dropdowns (e.g., {'City': 'Mum', 'State': 'Mah'})
  final Map<String, String> _searchQueries = {};

  @override
  void initState() {
    super.initState();
    final state = context.read<DataBloc>().state;
    _criteria = (state is DataLoaded) ? state.activeFilters.copyWith() : FilterCriteria();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 400, // Wide drawer for better visibility
      child: BlocBuilder<DataBloc, DataState>(
        builder: (context, state) {
          if (state is! DataLoaded) return Center(child: CircularProgressIndicator());

          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(20),
                  children: [
                    _sectionTitle("Time Period"),
                    _datePicker("Ordered On", _criteria.orderedDateRange, (val) => setState(() => _criteria = _criteria.copyWith(orderedDateRange: val))),
                    _datePicker("Invoice Date", _criteria.invoiceDateRange, (val) => setState(() => _criteria = _criteria.copyWith(invoiceDateRange: val))),

                    Divider(),
                    _sectionTitle("Order Details"),
                    _multiSelectDropdown("Order State", state.allOrderStates, _criteria.selectedStates, (l) => setState(() => _criteria.selectedStates = l)),

                    // Boolean Switch
                    SwitchListTile(
                      title: Text("Ready to Make Only"),
                      value: _criteria.readyToMake ?? false,
                      onChanged: (val) => setState(() => _criteria = _criteria.copyWith(readyToMake: val ? true : null)),
                    ),

                    Divider(),
                    _sectionTitle("Location"),
                    _searchableDropdown("City", state.allCities, _criteria.selectedCities, (l) => setState(() => _criteria.selectedCities = l)),
                    _searchableDropdown("State", state.allGeoStates, _criteria.selectedGeoStates, (l) => setState(() => _criteria.selectedGeoStates = l)),

                    Divider(),
                    _sectionTitle("Financials"),
                    Text("Invoice Amount: ₹${_criteria.amountRange?.start.round() ?? 0} - ₹${_criteria.amountRange?.end.round() ?? state.maxInvoiceAmount.round()}"),
                    RangeSlider(
                      min: 0,
                      max: state.maxInvoiceAmount > 0 ? state.maxInvoiceAmount : 10000,
                      divisions: 100,
                      values: _criteria.amountRange ?? RangeValues(0, state.maxInvoiceAmount > 0 ? state.maxInvoiceAmount : 10000),
                      onChanged: (val) => setState(() => _criteria = _criteria.copyWith(amountRange: val)),
                    ),
                  ],
                ),
              ),
              _buildBottomBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: AppTheme.subTitleStyle.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
    );
  }

  Widget _datePicker(String label, DateTimeRange? current, Function(DateTimeRange?) onSelect) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: TextStyle(fontSize: 14)),
      subtitle: Text(current == null ? "All Time" : "${current.start.year}-${current.start.month}-${current.start.day} to ${current.end.year}-${current.end.month}-${current.end.day}"),
      trailing: Icon(Icons.calendar_today, size: 18),
      onTap: () async {
        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onSelect(picked);
      },
    );
  }

  Widget _multiSelectDropdown(String label, List<String> options, List<String> selected, Function(List<String>) onChanged) {
    return ExpansionTile(
      title: Text(label),
      subtitle: Text("${selected.length} selected"),
      children: options.map((opt) {
        return CheckboxListTile(
          title: Text(opt),
          value: selected.contains(opt),
          onChanged: (val) {
            // Create a copy of the list to ensure state updates trigger correctly
            List<String> newSelected = List.from(selected);
            if (val == true) newSelected.add(opt); else newSelected.remove(opt);
            onChanged(newSelected);
          },
        );
      }).toList(),
    );
  }

  // --- NEW METHOD: Handles filtering large lists like City/State ---
  Widget _searchableDropdown(String label, List<String> options, List<String> selected, Function(List<String>) onChanged) {
    // Get the current search query for this specific dropdown label
    String searchQuery = _searchQueries[label] ?? '';

    // Filter options based on search query
    final filteredOptions = options
        .where((item) => item.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return ExpansionTile(
      title: Text(label),
      subtitle: Text("${selected.length} selected"),
      children: [
        // Search Bar inside the dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search $label...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
            ),
            onChanged: (val) {
              setState(() {
                _searchQueries[label] = val; // Update search query for this dropdown
              });
            },
          ),
        ),
        // Scrollable list of checkboxes
        Container(
          constraints: BoxConstraints(maxHeight: 250), // Limit height
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filteredOptions.length,
            itemBuilder: (context, index) {
              final opt = filteredOptions[index];
              return CheckboxListTile(
                title: Text(opt),
                value: selected.contains(opt),
                onChanged: (val) {
                  List<String> newSelected = List.from(selected);
                  if (val == true) {
                    newSelected.add(opt);
                  } else {
                    newSelected.remove(opt);
                  }
                  onChanged(newSelected);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) => Container(
    padding: EdgeInsets.only(top: 40, bottom: 20, left: 20, right: 20),
    color: AppTheme.primaryColor,
    child: Row(children: [Text("Filter Data", style: TextStyle(color: Colors.white, fontSize: 18)), Spacer(), CloseButton(color: Colors.white)]),
  );

  Widget _buildBottomBar(BuildContext context) => Container(
    padding: EdgeInsets.all(20),
    child: Row(children: [
      Expanded(child: OutlinedButton(onPressed: (){ setState(() => _criteria = FilterCriteria()); }, child: Text("Reset"))),
      SizedBox(width: 10),
      Expanded(child: ElevatedButton(
          style: AppTheme.primaryButtonStyle,
          onPressed: (){ context.read<DataBloc>().add(ApplyFilterEvent(_criteria)); Navigator.pop(context); },
          child: Text("Apply Filters")
      )),
    ]),
  );
}