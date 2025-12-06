import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:order_admin_panel/bloc/auth_bloc.dart';
import 'dashboard_screen.dart'; // We will create this next

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Panel Login")),
      // BlocListener listens for state changes (Success/Failure)
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            // Show error message (SnackBar)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: Colors.red),
            );
          } else if (state is AuthAuthenticated) {
            // Navigate to Dashboard on success
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => DashboardScreen(userRole: state.role))
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: "Email", border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                obscureText: true,
              ),
              SizedBox(height: 25),

              // BlocBuilder rebuilds ONLY the button when loading state changes
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthLoading) {
                    return CircularProgressIndicator();
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        // Trigger the Login Event
                        final email = emailController.text.trim();
                        final pass = passwordController.text.trim();

                        if(email.isNotEmpty && pass.isNotEmpty) {
                          context.read<AuthBloc>().add(LoginRequested(email, pass));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Please fill all fields"))
                          );
                        }
                      },
                      child: Text("Login"),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}