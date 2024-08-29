import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? verificationID;

  AuthBloc() : super(AuthInitState()) {
    on<CheckAuthenticationEvent>((event, emit) async {
      log('CheckAuthenticationEvent received');
      await _mapCheckAuthenticationToState(emit);
    });

    on<SendOTPEvent>((event, emit) async {
      log('SendOTPEvent received');
      await _mapSendOTPToState(event, emit);
    });

    on<VerifyOTPEvent>((event, emit) async {
      log('VerifyOTPEvent received');
      await _mapVerifyOTPToState(event, emit);
    });

    on<SignInWithPhoneEvent>((event, emit) async {
      log('SignInWithPhoneEvent received');
      await _mapSignInWithPhoneToState(event, emit);
    });

    on<LogOutEvent>((event, emit) async {
      log('LogOutEvent received');
      await _mapLogOutToState(emit);
    });

    on<AuthCodeSentEvent>((event, emit) async {
      log('AuthCodeSentEvent received');
      emit(AuthCodeSentState(event.verificationId));
    });

    on<AuthErrorEvent>((event, emit) async {
      log('AuthErrorEvent received');
      emit(AuthErrorState(event.errorMessage));
    });

    add(const CheckAuthenticationEvent());
  }

  Future<void> _mapCheckAuthenticationToState(Emitter<AuthState> emit) async {
    log('_mapCheckAuthenticationToState called');
    User? user = _firebaseAuth.currentUser;
    if (user != null) {
      emit(AuthLoggedInState(user));
    } else {
      emit(AuthLoggedOutState());
    }
  }

  Future<void> _mapSendOTPToState(
      SendOTPEvent event, Emitter<AuthState> emit) async {
    log('_mapSendOTPToState called');

    emit(AuthLoadingState());

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        codeSent: (String verificationId, int? forceResendingToken) {
          // Сохраняем полученный verificationId
          verificationID = verificationId;
          log('Verification ID: $verificationId');
          // Отправляем событие AuthCodeSentEvent
          add(AuthCodeSentEvent(verificationId: verificationId));
        },
        verificationCompleted: (PhoneAuthCredential phoneAuthCredential) {
          // Автоматическая верификация номера телефона
          add(SignInWithPhoneEvent(phoneAuthCredential));
        },
        verificationFailed: (FirebaseAuthException error) {
          // Ошибка верификации номера телефона
          add(AuthErrorEvent(error.message.toString()));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Автоматическое извлечение кода завершено
          log('Auto retrieval timeout, verification ID: $verificationId');
          // Сохраняем полученный verificationId
          verificationID = verificationId;
        },
      );

      // Дополнительно отправляем состояние загрузки после завершения отправки OTP
      emit(AuthLoadingState());
    } catch (error) {
      // Ошибка при отправке OTP
      emit(AuthErrorState(error.toString()));
    }
  }

  Future<void> _mapVerifyOTPToState(
      VerifyOTPEvent event, Emitter<AuthState> emit) async {
    log('_mapVerifyOTPToState called');
    emit(AuthLoadingState());

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationID!,
        smsCode: event.otp,
      );

      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        log('Authentication successful, user: ${userCredential.user!.uid}');
        emit(AuthLoggedInState(userCredential.user!));
      } else {
        log('No user found after authentication.');
        emit(AuthErrorState('No user found after sign in.'));
      }
    } catch (error) {
      log('Authentication failed: ${error.toString()}');
      emit(AuthErrorState(error.toString()));
    }
  }

  Future<void> _mapSignInWithPhoneToState(
      SignInWithPhoneEvent event, Emitter<AuthState> emit) async {
    log('_mapSignInWithPhoneToState called');
    emit(AuthLoadingState());

    try {
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(event.credential);
      if (userCredential.user != null) {
        emit(AuthLoggedInState(
            userCredential.user!)); // Убедитесь, что это состояние отправляется
        log('User logged in: ${userCredential.user!.uid}');
      } else {
        emit(AuthErrorState('No user found after sign in.'));
      }
    } catch (error) {
      emit(AuthErrorState(error.toString()));
    }
  }

  Future<void> _mapLogOutToState(Emitter<AuthState> emit) async {
    log('_mapLogOutToState called');
    emit(AuthLoadingState());
    await _firebaseAuth.signOut();
    emit(AuthLoggedOutState());
  }
}
