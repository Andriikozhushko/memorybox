import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth_bloc/auth_bloc.dart';
import '../blocs/auth_bloc/auth_event.dart';
import '../pages/auth_screens/start_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 0), () {
      if (mounted) {
        AuthBloc authBloc = BlocProvider.of<AuthBloc>(context);
        authBloc.add(const CheckAuthenticationEvent());
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class UnauthenticatedSplashScreen extends StatelessWidget {
  const UnauthenticatedSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StartScreen();
  }
}
