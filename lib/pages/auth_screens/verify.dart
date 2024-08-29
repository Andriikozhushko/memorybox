import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_event.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../blocs/buttomnavbar_cubit/buttombar_cubit.dart';
import '../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';

class VerifyPhoneNumber extends StatefulWidget {
  const VerifyPhoneNumber({super.key});

  @override
  VerifyPhoneNumberState createState() => VerifyPhoneNumberState();
}

class VerifyPhoneNumberState extends State<VerifyPhoneNumber> {
  late TextEditingController otpController;
  late FocusNode otpFocusNode;

  @override
  void initState() {
    super.initState();
    otpController = TextEditingController();
    otpFocusNode = FocusNode();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(otpFocusNode);
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
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
                      const Text('Введи код из смс, чтобы мы тебя запомнили'),
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
                          width: 300,
                          height: 62,
                          child: TextFormField(
                            focusNode: otpFocusNode,
                            controller: otpController,
                            maxLength: 10,
                            keyboardType: TextInputType.number,
                            onTap: () {},
                            style: dark20,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              prefixStyle: dark20,
                              border: InputBorder.none,
                              counterText: "",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 85),
                      BlocConsumer<AuthBloc, AuthState>(
                        listener: (context, state) {
                          if (state is AuthLoggedInState) {
                            log('Redirecting to SplashScreen from listener.');
                            Navigator.pushReplacementNamed(
                                context, '/asplashScreen');
                            final bottomNavBarVisibilityCubit =
                                context.read<BottomNavBarVisibilityCubit>();
                            bottomNavBarVisibilityCubit.showBottomNavBar();
                            context
                                .read<NavigationBloc>()
                                .add(NavigationEvents.home);
                          } else if (state is AuthErrorState) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.errorMessage),
                                duration: const Duration(milliseconds: 1500),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        builder: (context, state) {
                          if (state is AuthLoadingState) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        recordColor),
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
                                style: graysize18,
                              ),
                              onPressed: () {
                                BlocProvider.of<AuthBloc>(context).add(
                                  VerifyOTPEvent(otpController.text),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
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
                          color: grayTextColor,
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(21, 25, 21, 25),
                            child: Text(
                              'Регистрация привяжет твои сказки к облаку, после чего они всегда будут с тобой',
                              style: dark14,
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
}
