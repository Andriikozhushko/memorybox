import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthInitState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthCodeSentState extends AuthState {
  final String verificationId;
  AuthCodeSentState(this.verificationId);
}

class AuthCodeVerifiedState extends AuthState {}

class AuthLoggedInState extends AuthState {
  final User firebaseUser;
  AuthLoggedInState(this.firebaseUser);
}

class AuthLoggedOutState extends AuthState {}

class AuthErrorState extends AuthState {
  final String errorMessage;
  AuthErrorState(this.errorMessage);
}

class AuthNotAuthenticatedState extends AuthState {}

class AuthAuthenticatedState extends AuthState {}
