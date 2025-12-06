import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';

// EVENTS
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

class CheckAuthStatus extends AuthEvent {} // Useful for auto-login on app start

// STATES
abstract class AuthState extends Equatable {
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String role;
  final String userId;
  final String email;

  AuthAuthenticated({required this.role, required this.userId, required this.email});

  @override
  List<Object> get props => [role, userId, email];
}

class AuthFailure extends AuthState {
  final String error;
  AuthFailure(this.error);
}

// BLOC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {

    // 1. Handle Login
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.login(event.email, event.password);

        if (response['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          String safeUserId = response['user_id'].toString();
          String safeRole = response['role'].toString();
          String safeEmail = event.email; // We use the email they logged in with

          await prefs.setString('user_role', safeRole);
          await prefs.setString('user_id', safeUserId);
          await prefs.setString('user_email', safeEmail); // <--- SAVE EMAIL

          emit(AuthAuthenticated(
              role: safeRole,
              userId: safeUserId,
              email: safeEmail // <--- PASS EMAIL
          ));
        } else {
          emit(AuthFailure(response['message'] ?? "Login failed"));
        }
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });

    // 2. Handle Logout
    on<LogoutRequested>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      emit(AuthInitial());
    });

    // 3. Check Auth Status (Restore session)
    on<CheckAuthStatus>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      final userId = prefs.getString('user_id');
      final email = prefs.getString('user_email');

      if (role != null && userId != null && email != null) {
        emit(AuthAuthenticated(role: role, userId: userId, email: email));
      } else {
        emit(AuthInitial());
      }
    });
  }
}