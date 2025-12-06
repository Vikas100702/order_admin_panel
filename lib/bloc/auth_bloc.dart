import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';

// --- 1. EVENTS (Actions the user performs) ---
abstract class AuthEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

// --- 2. STATES (What the UI shows) ---
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String role; // 'superadmin', 'admin', or 'user'
  final String userId;

  AuthAuthenticated({required this.role, required this.userId});
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

// --- 3. BLOC (The Logic) ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {

    // Handle Login Logic
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading()); // Show spinner

      try {
        final response = await authRepository.login(event.email, event.password);

        if (response['status'] == 'success') {
          // Save to phone storage so they stay logged in (Optional for now, but good practice)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', response['role']);
          await prefs.setString('user_id', response['user_id']);

          emit(AuthAuthenticated(
              role: response['role'],
              userId: response['user_id']
          ));
        } else {
          emit(AuthFailure(response['message'] ?? "Login failed"));
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // Handle Logout Logic
    on<LogoutRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Remove saved data
      emit(AuthInitial()); // Go back to login screen
    });
  }
}