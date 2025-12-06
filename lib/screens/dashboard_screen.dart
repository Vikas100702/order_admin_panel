import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/screens/user_management_screen.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/data_bloc.dart';
import '../core/app_theme.dart';
import '../repositories/data_repository.dart';
import '../widgets/filter_drawer.dart'; // Import Filter Drawer
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userRole;

  const DashboardScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DataBloc(
        dataRepository: RepositoryProvider.of<DataRepository>(context),
      )..add(LoadDataEvent()),
      child: DashboardView(userRole: userRole),
    );
  }
}

class DashboardView extends StatefulWidget {
  final String userRole;
  const DashboardView({Key? key, required this.userRole}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key for Drawer
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickAndUploadFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result != null) {
      List<int> fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;
      context.read<DataBloc>().add(UploadFileEvent(fileBytes, fileName));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      key: _scaffoldKey, // Assign Key
      backgroundColor: AppTheme.bgColor,
      endDrawer: FilterDrawer(), // Add the Filter Drawer
      drawer: !isDesktop ? _buildSidebar(context) : null,
      appBar: !isDesktop
          ? AppBar(backgroundColor: AppTheme.primaryColor, title: Text("Dashboard", style: TextStyle(color: Colors.white)))
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) SizedBox(width: 250, child: _buildSidebar(context)),
          Expanded(
            child: Column(
              children: [
                _buildHeader(context, isDesktop),
                Expanded(
                  child: BlocConsumer<DataBloc, DataState>(
                    listener: (context, state) {
                      if (state is UploadSuccess) _showSnack(context, state.message, Colors.green);
                      if (state is DataError) _showSnack(context, state.message, AppTheme.errorColor);
                    },
                    builder: (context, state) {
                      if (state is DataLoading) return Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
                      if (state is DataLoaded) {
                        // FIX: Changed state.orders to state.filteredOrders
                        return _buildContent(state.filteredOrders, isDesktop);
                      }
                      return Center(child: Text("Welcome. Loading data...", style: AppTheme.subTitleStyle));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<dynamic> orders, bool isDesktop) {
    if (orders.isEmpty) return Center(child: Text("No Data Found"));

    // Check if we should show stats (Only for Admin/Superadmin)
    bool showStats = widget.userRole != 'user';

    if (isDesktop) {
      return SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Only show stats row if permission allows
            if(showStats) _buildStatsRow(orders, isDesktop),
            SizedBox(height: 20),
            _buildDesktopTable(orders),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          // Only show stats row if permission allows
          if(showStats)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: _buildStatsRow(orders, isDesktop),
          ),
          Expanded(child: _buildMobileList(orders)),
        ],
      );
    }
  }

  // --- STATS ---
  Widget _buildStatsRow(List<dynamic> orders, bool isDesktop) {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total Orders", "${orders.length}", Colors.blue)),
        SizedBox(width: 15),
        Expanded(child: _buildStatCard("Revenue", "₹${_calculateRevenue(orders)}", Colors.green)),
        if (isDesktop) ...[
          SizedBox(width: 15),
          Expanded(child: _buildStatCard("Pending", "12", Colors.orange)),
        ]
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 5),
          Text(value, style: AppTheme.titleStyle.copyWith(fontSize: 22)),
        ],
      ),
    );
  }

  // --- DESKTOP TABLE ---
  Widget _buildDesktopTable(List<dynamic> data) {
    return Theme(
      data: Theme.of(context).copyWith(cardColor: Colors.white, dividerColor: Colors.grey[200]),
      child: PaginatedDataTable(
        header: Text("Recent Transactions", style: AppTheme.subTitleStyle),
        columns: _getColumns(),
        source: OrderDataSource(data, context),
        onRowsPerPageChanged: (r) {
          setState(() {
            _rowsPerPage = r!;
          });
        },
        rowsPerPage: _rowsPerPage,
        columnSpacing: 20,
        horizontalMargin: 20,
        showCheckboxColumn: false,
      ),
    );
  }

  // --- MOBILE LIST ---
  Widget _buildMobileList(List<dynamic> data) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final row = data[index];
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.bgColor,
              child: Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 20),
            ),
            title: Text(row['product_name'] ?? 'Unknown', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${row['order_id']}\n₹${row['invoice_amount']}", style: TextStyle(fontSize: 12)),
            trailing: _getStatusChip(row['order_state'] ?? ''),
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow("Buyer", row['buyer_name']),
                    _detailRow("City", row['city']),
                    _detailRow("Date", row['ordered_on']),
                    _detailRow("Status", row['order_state']),
                    _detailRow("SKU", row['sku']),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: AppTheme.primaryColor,
      child: Column(
        children: [
          SizedBox(height: 40),
          Icon(Icons.analytics, color: Colors.white, size: 50),
          SizedBox(height: 10),
          Text("Admin Panel", style: AppTheme.titleStyle.copyWith(color: Colors.white, fontSize: 20)),
          SizedBox(height: 40),
          _buildMenuLink(Icons.dashboard, "Dashboard", true, () {}),

          // Manage Users Link (Contains List + Create button)
          if (widget.userRole != 'user')
            _buildMenuLink(Icons.people, "Manage Users", false, () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>
                      UserManagementScreen(currentUserRole: widget.userRole))
              );
            }),

          Spacer(),
          Divider(color: Colors.white24),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.white70),
            title: Text("Logout", style: TextStyle(color: Colors.white70)),
            onTap: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuLink(IconData icon, String title, bool isActive,
      VoidCallback onTap) {
    return Container(
      color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: isActive ? Colors.white : Colors.white54),
        title: Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white54)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.white,
      child: Row(
        children: [
          if (isDesktop) Text("Overview", style: AppTheme.titleStyle.copyWith(fontSize: 20)),
          if (isDesktop) Spacer(),
          Expanded(
            flex: isDesktop ? 0 : 1,
            child: Container(
              width: isDesktop ? 300 : null,
              height: 45,
              decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(8)),
              child: TextField(
                controller: _searchController,
                // FIX: Use ApplyFilterEvent instead of LoadDataEvent
                onChanged: (val) {
                  final state = context.read<DataBloc>().state;
                  if (state is DataLoaded) {
                    final newCriteria = state.activeFilters.copyWith(searchQuery: val);
                    context.read<DataBloc>().add(ApplyFilterEvent(newCriteria));
                  }
                },
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 8),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          // FIX: Added Filter Button
          IconButton(
            icon: Icon(Icons.filter_list_alt, color: AppTheme.accentColor),
            tooltip: "Advanced Filters",
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          SizedBox(width: 10),
          if (widget.userRole != 'user')
            ElevatedButton.icon(
              onPressed: () => _pickAndUploadFile(context),
              icon: Icon(Icons.cloud_upload, size: 18),
              label: Text(isDesktop ? "Upload CSV" : "Upload"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey)),
          Expanded(child: Text(value ?? "-", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _getStatusChip(String status) {
    Color color = Colors.orange;
    if (status.toLowerCase().contains('shipped')) color = Colors.blue;
    if (status.toLowerCase().contains('delivered')) color = Colors.green;
    if (status.toLowerCase().contains('cancelled')) color = Colors.red;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showSnack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  String _calculateRevenue(List<dynamic> orders) {
    double total = 0;
    for (var o in orders) {
      total += double.tryParse(o['invoice_amount']?.toString() ?? '0') ?? 0;
    }
    return total.toStringAsFixed(0);
  }

  List<DataColumn> _getColumns() {
    return const [
      DataColumn(label: Text('Ordered On')),
      DataColumn(label: Text('Shipment ID')),
      DataColumn(label: Text('Order Item ID')),
      DataColumn(label: Text('Order ID')),
      DataColumn(label: Text('HSN Code')),
      DataColumn(label: Text('Order State')),
      DataColumn(label: Text('Order Type')),
      DataColumn(label: Text('FSN')),
      DataColumn(label: Text('SKU')),
      DataColumn(label: Text('Product')),
      DataColumn(label: Text('Invoice No')),
      DataColumn(label: Text('CGST')),
      DataColumn(label: Text('IGST')),
      DataColumn(label: Text('SGST')),
      DataColumn(label: Text('Invoice Date')),
      DataColumn(label: Text('Amount')),
      DataColumn(label: Text('Selling Price')),
      DataColumn(label: Text('Shipping Charge')),
      DataColumn(label: Text('Qty')),
      DataColumn(label: Text('Price inc Subsidy')),
      DataColumn(label: Text('Buyer Name')),
      DataColumn(label: Text('Ship To Name')),
      DataColumn(label: Text('Address 1')),
      DataColumn(label: Text('Address 2')),
      DataColumn(label: Text('City')),
      DataColumn(label: Text('State')),
      DataColumn(label: Text('Pin Code')),
      DataColumn(label: Text('Dispatch After')),
      DataColumn(label: Text('Dispatch By')),
      DataColumn(label: Text('Form Req')),
      DataColumn(label: Text('Tracking ID')),
      DataColumn(label: Text('Pkg Length')),
      DataColumn(label: Text('Pkg Breadth')),
      DataColumn(label: Text('Pkg Height')),
      DataColumn(label: Text('Pkg Weight')),
      DataColumn(label: Text('Ready to Make')),
      DataColumn(label: Text('Attachment')),
    ];
  }
}

// --- DATA SOURCE CLASS (The Secret to Performance) ---
class OrderDataSource extends DataTableSource {
  final List<dynamic> _data;
  final BuildContext context;

  OrderDataSource(this._data, this.context);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final row = _data[index];

    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(row['ordered_on'] ?? '')),
        DataCell(Text(row['shipment_id'] ?? '')),
        DataCell(Text(row['order_item_id'] ?? '')),
        DataCell(Text(row['order_id'] ?? '')),
        DataCell(Text(row['hsn_code'] ?? '')),
        DataCell(Text(row['order_state'] ?? '')),
        DataCell(Text(row['order_type'] ?? '')),
        DataCell(Text(row['fsn'] ?? '')),
        DataCell(Text(row['sku'] ?? '')),
        DataCell( Text(row['product_name'] ?? '')),
        DataCell(Text(row['invoice_no'] ?? '')),
        DataCell(Text(row['cgst'] ?? '')),
        DataCell(Text(row['igst'] ?? '')),
        DataCell(Text(row['sgst'] ?? '')),
        DataCell(Text(row['invoice_date'] ?? '')),
        DataCell(Text(row['invoice_amount'] ?? '')),
        DataCell(Text(row['selling_price_per_item'] ?? '')),
        DataCell(Text(row['shipping_charges'] ?? '')),
        DataCell(Text(row['quantity'] ?? '')),
        DataCell(Text(row['price_inc_subsidy'] ?? '')),
        DataCell(Text(row['buyer_name'] ?? '')),
        DataCell(Text(row['ship_to_name'] ?? '')),
        DataCell(Text(row['address_line_1'] ?? '')),
        DataCell(Text(row['address_line_2'] ?? '')),
        DataCell(Text(row['city'] ?? '')),
        DataCell(Text(row['state'] ?? '')),
        DataCell(Text(row['pin_code'] ?? '')),
        DataCell(Text(row['dispatch_after_date'] ?? '')),
        DataCell(Text(row['dispatch_by_date'] ?? '')),
        DataCell(Text(row['form_requirement'] ?? '')),
        DataCell(Text(row['tracking_id'] ?? '')),
        DataCell(Text(row['package_length'] ?? '')),
        DataCell(Text(row['package_breadth'] ?? '')),
        DataCell(Text(row['package_height'] ?? '')),
        DataCell(Text(row['package_weight'] ?? '')),
        DataCell(Text(row['ready_to_make'] ?? '')),
        DataCell(Text(row['with_attachment'] ?? '')),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _data.length;
  @override
  int get selectedRowCount => 0;
}