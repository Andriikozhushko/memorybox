import 'dart:async';

import 'package:flutter/material.dart';

import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../home_screen/homescreen.dart';

class AuthenticatedSplashScreen extends StatefulWidget {
  const AuthenticatedSplashScreen({super.key});

  @override
  AuthenticatedSplashScreenState createState() =>
      AuthenticatedSplashScreenState();
}

class AuthenticatedSplashScreenState extends State<AuthenticatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(_animationController);
    _timer = Timer(const Duration(seconds: 5), () {
      final navigatorContext = context;
      Navigator.of(navigatorContext).pushReplacement(MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF6F6F6),
          ),
          ClipPath(
            clipper: EllipseClipper(),
            child: Container(
              color: const Color(0xFF8C84E2),
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
                        'Ты супер!',
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
              top: 100,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 300,
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
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(21, 25, 21, 25),
                            child: Text(
                              'Мы рады тебя видеть',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _animation.value,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/img/icon/hearts_icon.png',
                            height: 60,
                            width: 60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
