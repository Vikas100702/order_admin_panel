import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/core/app_theme.dart';
import 'package:order_admin_panel/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Change Password Controllers
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null) return;

    final repo = context.read<AuthRepository>();
    final response = await repo.getProfile(_userId!);

    if (response['status'] == 'success' && mounted) {
      final data = response['data'];
      setState(() {
        _nameController.text = data['full_name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to load profile"),
          backgroundColor: Colors.red,
        ));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final repo = context.read<AuthRepository>();
    final response = await repo.updateProfile(
      userId: _userId!,
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);
    _showMessage(response['message'], response['status'] == 'success');
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _oldPassController,
              decoration: AppTheme.inputDecoration("Old Password", Icons.lock_outline),
              obscureText: true,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _newPassController,
              decoration: AppTheme.inputDecoration("New Password", Icons.lock),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel")),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: () async {
              Navigator.pop(ctx);
              await _changePassword();
            },
            child: Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    if (_oldPassController.text.isEmpty || _newPassController.text.isEmpty) {
      _showMessage("Please fill all fields", false);
      return;
    }

    // Show global loading if preferred, or just snackbar
    final repo = context.read<AuthRepository>();
    final response = await repo.changePassword(
      userId: _userId!,
      oldPassword: _oldPassController.text,
      newPassword: _newPassController.text,
    );

    // Clear fields
    _oldPassController.clear();
    _newPassController.clear();

    _showMessage(response['message'], response['status'] == 'success');
  }

  void _showMessage(String msg, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 600),
          padding: EdgeInsets.all(20),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: EdgeInsets.all(30),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Edit Details", style: AppTheme.titleStyle),
                    SizedBox(height: 30),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: AppTheme.inputDecoration("Full Name", Icons.person),
                      validator: (v) => v!.isEmpty ? "Name required" : null,
                    ),
                    SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: AppTheme.inputDecoration("Email", Icons.email),
                      validator: (v) => !v!.contains("@") ? "Invalid Email" : null,
                    ),
                    SizedBox(height: 30),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: AppTheme.primaryButtonStyle,
                            onPressed: _updateProfile,
                            child: Text("Save Changes"),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(),
                    SizedBox(height: 10),

                    // Change Password Button
                    TextButton.icon(
                      onPressed: _showChangePasswordDialog,
                      icon: Icon(Icons.security, color: AppTheme.primaryColor),
                      label: Text("Change Password", style: TextStyle(color: AppTheme.primaryColor)),
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