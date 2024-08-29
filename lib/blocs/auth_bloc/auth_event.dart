import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SendOTPEvent extends AuthEvent {
  final String phoneNumber;

  const SendOTPEvent(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

class VerifyOTPEvent extends AuthEvent {
  final String otp;

  const VerifyOTPEvent(this.otp);

  @override
  List<Object> get props => [otp];
}

class CheckAuthenticationEvent extends AuthEvent {
  const CheckAuthenticationEvent();
}

class SignInWithPhoneEvent extends AuthEvent {
  final AuthCredential credential;

  const SignInWithPhoneEvent(this.credential);

  @override
  List<Object> get props => [credential];
}

class LogOutEvent extends AuthEvent {
  const LogOutEvent();
}
class SendPhoneNumberEvent extends AuthEvent {
  final String phoneNumber;

  const SendPhoneNumberEvent(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}
class AuthCodeSentEvent extends AuthEvent {
  final String verificationId;

  const AuthCodeSentEvent({required this.verificationId});

  @override
  List<Object> get props => [verificationId];
}

class AuthErrorEvent extends AuthEvent {
  final String errorMessage;

  const AuthErrorEvent(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
