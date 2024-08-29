import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:memory_box/pages/auth_screens/verify.dart';
import 'package:memory_box/pages/home_screen/homescreen.dart';

import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_event.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';

class SignInScreen1 extends StatefulWidget {
  const SignInScreen1({super.key});

  @override
  SignInScreen1State createState() => SignInScreen1State();
}

class SignInScreen1State extends State<SignInScreen1>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController phoneController = TextEditingController();
  final FocusNode phoneFocusNode = FocusNode();
  final maskFormatter = MaskTextInputFormatter(
    mask: '+380 (##) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    log('SignInScreen1State initialized');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    log('SignInScreen1State build called');

    return Scaffold(
      backgroundColor: grayTextColor,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            ClipPath(
              clipper: EllipseClipper(),
              child: Container(
                color: collectionsColor,
                height: MediaQuery.of(context).size.height * 0.4,
                child: const Center(
                  child: SizedBox(
                    width: 300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 30,
                        ),
                        Text(
                          'Регистрация',
                          style: graysize48,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 47.0,
                right: 47.0,
                top: 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.43),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Введи номер телефона'),
                      const SizedBox(
                        height: 20,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: grayTextColor,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2B000000),
                              offset: Offset(0, 4),
                              blurRadius: 11,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 62,
                          child: TextFormField(
                            controller: phoneController,
                            focusNode: phoneFocusNode,
                            maxLength: 19,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [maskFormatter],
                            style: dark20,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '+380 (XX) XXX XX XX',
                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 85),
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          log('AuthBloc state changed: ${state.runtimeType}');
                          if (state is AuthCodeSentState) {
                            log('Received AuthCodeSentState');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VerifyPhoneNumber(),
                              ),
                            );
                          } else if (state is AuthErrorState) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.errorMessage),
                                duration: const Duration(milliseconds: 600),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: () {
                              String phoneNumber = phoneController.text;
                              log('Sending OTP for phone number: $phoneNumber');
                              BlocProvider.of<AuthBloc>(context)
                                  .add(SendOTPEvent(phoneNumber));
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all<Color>(recordColor),
                              minimumSize: MaterialStateProperty.all<Size>(
                                  const Size(300, 50)),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                            ),
                            child: const Text(
                              'Продолжить',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      TextButton(
                        onPressed: () {
                          log('Navigating to HomeScreen without signing in');
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                          context
                              .read<NavigationBloc>()
                              .add(NavigationEvents.home);
                        },
                        child: const Text(
                          'Позже',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Container(
                        width: 285,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1C000000),
                              offset: Offset(0, 4),
                              blurRadius: 7,
                              spreadRadius: 0,
                            ),
                          ],
                          color: const Color(0xFFF6F6F6),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(21, 25, 21, 25),
                            child: Text(
                              'Регистрация привяжет твои сказки к облаку, после чего они всегда будут с тобой',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    log('SignInScreen1State disposed');
    super.dispose();
  }
}
