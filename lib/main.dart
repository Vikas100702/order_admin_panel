import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'repositories/auth_repository.dart';
import 'repositories/data_repository.dart';
import 'screens/login_screen.dart';
import 'widgets/session_timeout_listener.dart'; // Import the new widget

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => AuthRepository()),
        RepositoryProvider(create: (context) => DataRepository()),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        ),
        child: MaterialApp(
          title: 'Admin Panel',
          scrollBehavior: AppScrollBehavior(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue),
          // 1. Wrap the app content in the SessionTimeoutListener
          builder: (context, child) {
            return SessionTimeoutListener(
              duration: const Duration(hours: 1), // Set timeout to 1 Hour
              child: child!,
            );
          },
          home: const LoginScreen(),
        ),
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}