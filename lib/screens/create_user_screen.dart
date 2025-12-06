import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/bloc/auth_bloc.dart';
import '../repositories/auth_repository.dart';
import '../core/app_theme.dart';

class CreateUserScreen extends StatefulWidget {
  final String creatorRole;
  final Map<String, dynamic>? userToEdit; // Null if creating, Map if editing

  const CreateUserScreen({
    super.key,
    required this.creatorRole,
    this.userToEdit
  });

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.userToEdit != null;

    if (_isEditing) {
      // Pre-fill data for editing
      _fullNameController.text = widget.userToEdit!['full_name'] ?? ''; // Use full_name key
      _emailController.text = widget.userToEdit!['email'] ?? '';
      _selectedRole = widget.userToEdit!['role'];
    }

    // Role restrictions for Admin creator
    if (widget.creatorRole == 'admin' && !_isEditing) {
      _selectedRole = 'user';
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a role")));
      return;
    }

    setState(() => _isLoading = true);
    final repo = context.read<AuthRepository>();
    Map<String, dynamic> response;

    if (_isEditing) {
      // UPDATE EXISTING USER (No Password, No Email change logic here usually)
      response = await repo.updateUser(
        userId: widget.userToEdit!['id'].toString(),
        fullName: _fullNameController.text.trim(),
        role: _selectedRole!,
        requesterRole: widget.creatorRole,
      );
    } else {
      // CREATE NEW USER
      final authState = context.read<AuthBloc>().state;
      String myEmail = 'system';
      if (authState is AuthAuthenticated) myEmail = authState.email;

      response = await repo.createUser(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole!,
        creatorRole: widget.creatorRole,
        creatorEmail: myEmail,
      );
    }

    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? "User Updated Successfully!" : "User Created Successfully!"),
        backgroundColor: Colors.green,
      ));
      if (!_isEditing) {
        _fullNameController.clear();
        _emailController.clear();
        _passwordController.clear();
        // Reset role only if allowed to choose (Superadmin)
        if (widget.creatorRole == 'superadmin') setState(() => _selectedRole = null);
      } else {
        Navigator.pop(context, true); // Return true to refresh list
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? "Error processing request"),
        backgroundColor: AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define available roles
    List<String> roleOptions = [];
    if (widget.creatorRole == 'superadmin') {
      roleOptions = ['admin', 'user'];
    } else if (widget.creatorRole == 'admin') {
      roleOptions = ['user'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit User Details" : "Create New Account", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppTheme.bgColor,
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 500),
          padding: EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isEditing ? "Update Profile" : "Add User", style: AppTheme.titleStyle),
                    SizedBox(height: 8),
                    Text(_isEditing ? "Modify user details below." : "Enter details to create account.", style: AppTheme.subTitleStyle),
                    SizedBox(height: 30),

                    // FULL NAME INPUT
                    TextFormField(
                      controller: _fullNameController,
                      decoration: AppTheme.inputDecoration("Full Name", Icons.person_outline),
                      validator: (val) => val != null && val.trim().isNotEmpty ? null : "Full Name is required",
                    ),
                    SizedBox(height: 20),

                    // EMAIL INPUT (Read Only if Editing)
                    TextFormField(
                      controller: _emailController,
                      decoration: AppTheme.inputDecoration("Email Address", Icons.email_outlined),
                      readOnly: _isEditing, // Prevent email editing
                      style: _isEditing ? TextStyle(color: Colors.grey[600]) : null,
                      validator: (val) => val != null && val.contains('@') ? null : "Enter a valid email",
                    ),
                    SizedBox(height: 20),

                    // PASSWORD INPUT (Hide if Editing)
                    if (!_isEditing) ...[
                      TextFormField(
                        controller: _passwordController,
                        decoration: AppTheme.inputDecoration("Password", Icons.lock_outline),
                        obscureText: true,
                        validator: (val) => val != null && val.length >= 6 ? null : "Min 6 characters required",
                      ),
                      SizedBox(height: 20),
                    ],

                    // ROLE DROPDOWN
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: AppTheme.inputDecoration("Assign Role", Icons.security),
                      items: roleOptions.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRole = val),
                      validator: (val) => val == null ? "Please select a role" : null,
                    ),
                    SizedBox(height: 30),

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: AppTheme.primaryButtonStyle,
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(_isEditing ? "Update User" : "Create Account"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}