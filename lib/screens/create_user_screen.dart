import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/bloc/auth_bloc.dart';
import '../repositories/auth_repository.dart';
import '../core/app_theme.dart';

class CreateUserScreen extends StatefulWidget {
  final String creatorRole; // 'superadmin' or 'admin'

  const CreateUserScreen({Key? key, required this.creatorRole}) : super(key: key);

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRole;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If the creator is an 'admin', they can ONLY create 'user' accounts.
    // So we pre-select 'user' for them.
    if (widget.creatorRole == 'admin') {
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

    final authState = context.read<AuthBloc>().state;
    String myEmail = '';

    if(authState is AuthAuthenticated) {
      myEmail = authState.email;
    }

    final repo = context.read<AuthRepository>();
    final response = await repo.createUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole!,
      creatorRole: widget.creatorRole,
      creatorEmail: myEmail,
    );

    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("User Created Successfully!"),
        backgroundColor: Colors.green,
      ));
      // Clear form
      _emailController.clear();
      _passwordController.clear();
      if (widget.creatorRole == 'superadmin') setState(() => _selectedRole = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? "Error creating user"),
        backgroundColor: AppTheme.errorColor,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define available roles based on who is logged in
    List<String> roleOptions = [];
    if (widget.creatorRole == 'superadmin') {
      roleOptions = ['admin', 'user'];
    } else if (widget.creatorRole == 'admin') {
      roleOptions = ['user'];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Create New Account", style: TextStyle(color: Colors.white)),
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
                    Text("Add User", style: AppTheme.titleStyle),
                    SizedBox(height: 8),
                    Text("Enter details to create a new account.", style: AppTheme.subTitleStyle),
                    SizedBox(height: 30),

                    // EMAIL INPUT
                    TextFormField(
                      controller: _emailController,
                      decoration: AppTheme.inputDecoration("Email Address", Icons.email_outlined),
                      validator: (val) => val != null && val.contains('@') ? null : "Enter a valid email",
                    ),
                    SizedBox(height: 20),

                    // PASSWORD INPUT
                    TextFormField(
                      controller: _passwordController,
                      decoration: AppTheme.inputDecoration("Password", Icons.lock_outline),
                      obscureText: true,
                      validator: (val) => val != null && val.length >= 6 ? null : "Min 6 characters required",
                    ),
                    SizedBox(height: 20),

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
                            : Text("Create Account"),
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