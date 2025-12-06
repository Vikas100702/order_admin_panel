import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../core/app_theme.dart';
import 'dashboard_screen.dart';

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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error), backgroundColor: AppTheme.errorColor),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardScreen(userRole: state.role)),
            );
          }
        },
        child: Row(
          children: [
            // 1. DESKTOP SIDE IMAGE (Hidden on Mobile)
            if (size.width > 900)
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    image: DecorationImage(
                      image: NetworkImage("https://images.unsplash.com/photo-1556742049-0cfed4f7a07d?auto=format&fit=crop&w=1350&q=80"), // Placeholder
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Order Admin Panel", style: AppTheme.titleStyle.copyWith(color: Colors.white, fontSize: 36)),
                        SizedBox(height: 10),
                        Text("Manage your business efficiently.", style: AppTheme.bodyStyle.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),

            // 2. LOGIN FORM SECTION
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(32),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Welcome Back!", style: AppTheme.titleStyle),
                        SizedBox(height: 8),
                        Text("Please enter your details to sign in.", style: AppTheme.subTitleStyle),
                        SizedBox(height: 40),

                        TextField(
                          controller: emailController,
                          decoration: AppTheme.inputDecoration("Email Address", Icons.email_outlined),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: passwordController,
                          decoration: AppTheme.inputDecoration("Password", Icons.lock_outlined),
                          obscureText: true,
                        ),
                        SizedBox(height: 30),

                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthLoading) {
                              return Center(child: CircularProgressIndicator(color: AppTheme.accentColor));
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  final email = emailController.text.trim();
                                  final pass = passwordController.text.trim();
                                  if (email.isNotEmpty && pass.isNotEmpty) {
                                    context.read<AuthBloc>().add(LoginRequested(email, pass));
                                  }
                                },
                                style: AppTheme.primaryButtonStyle,
                                child: Text("Login"),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}