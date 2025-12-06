import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/bloc/auth_bloc.dart';
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

  // 1. Fetch Users & Apply Filters
  Future<void> _fetchUsers() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final repo = context.read<AuthRepository>();
      final authState = context.read<AuthBloc>().state;
      String myEmail = '';

      // Get current logged-in user's email for filtering
      if (authState is AuthAuthenticated) {
        myEmail = authState.email;
      }

      final allUsers = await repo.getUsers(widget.currentUserRole);

      // --- FILTERING LOGIC ---
      final filteredUsers = allUsers.where((user) {
        String role = user['role'] ?? 'user';
        String createdBy = user['created_by'] ?? '';

        // Requirement 1: Superadmin should not be visible to anyone in this list
        if (role == 'superadmin') return false;

        // Requirement 2: Admin can ONLY view/manage users they created
        if (widget.currentUserRole == 'admin') {
          return createdBy == myEmail;
        }

        // Superadmin role (logged in user) sees everyone else
        return true;
      }).toList();

      setState(() {
        _users = filteredUsers;
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
  void _confirmDelete(String userId) {
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

  // 3. Edit User Navigation
  void _editUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateUserScreen(
          creatorRole: widget.currentUserRole,
          userToEdit: user, // Pass user data for editing
        ),
      ),
    );
    // If update was successful (returns true), refresh list
    if (result == true) _fetchUsers();
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
          : _users.isEmpty
          ? Center(child: Text("No users found."))
          : RefreshIndicator(
        onRefresh: _fetchUsers,
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            final role = user['role'] ?? 'user';
            final email = user['email'] ?? 'Unknown';
            final fullName = user['full_name'] ?? 'No Name Found'; // Use full_name
            final createdBy = user['created_by'] ?? 'System';

            return Card(
              margin: EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getRoleColor(role),
                  child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
                      style: TextStyle(color: Colors.white)
                  ),
                ),
                title: Text("$fullName", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email, style: TextStyle(color: Colors.grey[700])),
                    SizedBox(height: 4),
                    Text("Role: ${role.toUpperCase()} | Created By: $createdBy", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // EDIT BUTTON
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editUser(user),
                      tooltip: "Edit User",
                    ),
                    // DELETE BUTTON
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _confirmDelete(user['id'].toString()),
                      tooltip: "Delete User",
                    ),
                  ],
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