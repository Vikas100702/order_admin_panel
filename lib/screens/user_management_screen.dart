import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import '../core/app_theme.dart';
import 'create_user_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final String currentUserRole;

  const UserManagementScreen({Key? key, required this.currentUserRole}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // 1. Fetch Users
  Future<void> _fetchUsers() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final repo = context.read<AuthRepository>();
      final users = await repo.getUsers(widget.currentUserRole);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // 2. Delete User Confirmation
  void _confirmDelete(String userId, String userRole) {
    if (widget.currentUserRole == 'admin' && (userRole == 'admin' || userRole == 'superadmin')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("You cannot delete this user.")));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete User?"),
        content: Text("Are you sure you want to remove this user? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteUser(userId);
            },
            child: Text("Delete"),
          )
        ],
      ),
    );
  }

  // 3. Perform Deletion
  Future<void> _deleteUser(String userId) async {
    final repo = context.read<AuthRepository>();
    final response = await repo.deleteUser(userId, widget.currentUserRole);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User deleted successfully"), backgroundColor: Colors.green));
      _fetchUsers(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message']), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("Manage Users", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.accentColor,
        onPressed: () async {
          // Navigate to Create Screen and refresh list when coming back
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateUserScreen(creatorRole: widget.currentUserRole)),
          );
          _fetchUsers();
        },
        label: Text("Add New User"),
        icon: Icon(Icons.person_add),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text("Error: $_errorMessage", style: TextStyle(color: Colors.red)))
          : RefreshIndicator(
        onRefresh: _fetchUsers,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            final role = user['role'] ?? 'user';
            final email = user['email'] ?? 'Unknown';
            final createdBy = user['created_by'] ?? 'System';
            final date = user['created_at'] ?? '-';

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(email, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text("Role: ${role.toUpperCase()}"),
                    Text("Created By: $createdBy | On: $date", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _confirmDelete(user['id'].toString(), role),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'superadmin': return Colors.purple;
      case 'admin': return Colors.blue;
      default: return Colors.grey;
    }
  }
}