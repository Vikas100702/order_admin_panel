import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class SessionTimeoutListener extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SessionTimeoutListener({
    super.key,
    required this.child,
    this.duration = const Duration(hours: 1), // Default timeout: 1 hour
  });

  @override
  State<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends State<SessionTimeoutListener> {
  Timer? _timer;

  // Start or Restart the timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.duration, () {
      _handleTimeout();
    });
  }

  // Handle what happens when the timer expires
  void _handleTimeout() {
    if (context.mounted) {
      final authBloc = context.read<AuthBloc>();
      // Only trigger logout if currently authenticated
      if (authBloc.state is AuthAuthenticated) {
        authBloc.add(LogoutRequested());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Session expired due to inactivity."),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Called on any user interaction
  void _onInteraction() {
    // Only reset timer if the user is authenticated
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State changes to start/stop the timer automatically
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _startTimer();
        } else {
          _timer?.cancel();
        }
      },
      // Listener wraps the child to detect gestures
      child: Listener(
        behavior: HitTestBehavior.translucent, // Catch events even on empty space
        onPointerDown: (_) => _onInteraction(), // Taps/Clicks
        onPointerMove: (_) => _onInteraction(), // Mouse movement / Drag
        onPointerHover: (_) => _onInteraction(), // Web Mouse Hover
        child: widget.child,
      ),
    );
  }
}