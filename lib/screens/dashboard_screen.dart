import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/data_bloc.dart';
import '../repositories/data_repository.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userRole;

  const DashboardScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We wrap the entire screen in the DataBloc Provider so it can fetch data
    return BlocProvider(
      create: (context) => DataBloc(
        dataRepository: RepositoryProvider.of<DataRepository>(context),
      )..add(LoadDataEvent()), // Immediately load data when screen opens
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

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  // To optimize search, you might want to use a "Debouncer" in production,
  // but for now, we will search as they type.

  void _pickAndUploadFile(BuildContext context) async {
    // 1. Pick the file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // Important for Web: This gives us the bytes
    );

    if (result != null) {
      // 2. Get file bytes (Required for Web Uploads)
      List<int> fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;

      // 3. Trigger Bloc Event
      context.read<DataBloc>().add(UploadFileEvent(fileBytes, fileName));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard (${widget.userRole})"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginScreen())
              );
            },
          )
        ],
      ),
      body: BlocListener<DataBloc, DataState>(
        listener: (context, state) {
          if (state is UploadSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
          } else if (state is DataError) {
            debugPrint("Error : ${state.message}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- TOP ROW: Search & Upload ---
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Order ID, Product, City...",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        context.read<DataBloc>().add(LoadDataEvent(query: value));
                      },
                    ),
                  ),
                  SizedBox(width: 10),

                  // Only show Upload button if role is NOT 'user'
                  if (widget.userRole == 'superadmin' || widget.userRole == 'admin')
                    ElevatedButton.icon(
                      onPressed: () => _pickAndUploadFile(context),
                      icon: Icon(Icons.upload_file),
                      label: Text("Upload CSV"),
                      // style: ElevatedButton.styleFrom(height: 50),
                    ),
                ],
              ),
              SizedBox(height: 20),

              // --- DATA TABLE ---
              Expanded(
                child: BlocBuilder<DataBloc, DataState>(
                  builder: (context, state) {
                    if (state is DataLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is DataLoaded) {
                      if (state.orders.isEmpty) {
                        return Center(child: Text("No data found. Upload a CSV!"));
                      }
                      return _buildDataTable(state.orders);
                    }
                    return Center(child: Text("Welcome. Loading data..."));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTable(List<dynamic> data) {
    // Note: We use SingleChildScrollView for vertical scrolling,
    // and another for horizontal scrolling, wrapped in Scrollbar widgets.
    return Scrollbar(
      // VERTICAL SCROLLBAR
      controller: _verticalController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        child: Scrollbar(
          // HORIZONTAL SCROLLBAR
          controller: _horizontalController,
          thumbVisibility: true,
          trackVisibility: true,
          notificationPredicate: (notif) => notif.depth == 1,
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
              columns: const [
                // ------------------ DATA COLUMNS (37 TOTAL) ------------------
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
                DataColumn(label: Text('Invoice Amount')),
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
              ],
              rows: data.map<DataRow>((row) {
                return DataRow(
                  cells: [
                    // ------------------ DATA CELLS (37 TOTAL) ------------------
                    DataCell(Text(row['ordered_on'] ?? '')),
                    DataCell(Text(row['shipment_id'] ?? '')),
                    DataCell(Text(row['order_item_id'] ?? '')),
                    DataCell(Text(row['order_id'] ?? '')),
                    DataCell(Text(row['hsn_code'] ?? '')),
                    DataCell(Text(row['order_state'] ?? '')),
                    DataCell(Text(row['order_type'] ?? '')),
                    DataCell(Text(row['fsn'] ?? '')),
                    DataCell(Text(row['sku'] ?? '')),
                    DataCell(Container(width: 150, child: Text(row['product_name'] ?? '', overflow: TextOverflow.ellipsis))),
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
                    DataCell(Container(width: 200, child: Text(row['address_line_1'] ?? '', overflow: TextOverflow.ellipsis))),
                    DataCell(Container(width: 200, child: Text(row['address_line_2'] ?? '', overflow: TextOverflow.ellipsis))),
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
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}