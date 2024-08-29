import 'package:flutter/material.dart';
import 'package:memory_box/pages/auth_screens/sign_in.dart';

import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

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
                          'MemoryBox',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 90.0),
                          child: Text(
                            'Твой голос всегда рядом',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1,
                            ),
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
                  SizedBox(
                    width: 310,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Привет!',
                          style: dark24,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        const Text(
                          'Мы рады видеть тебя здесь. Это приложение поможет записывать сказки и держать их в удобном месте не заполняя память на телефоне',
                          style: dark16,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 85),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen1(),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                const Color(0xFFF1B488)),
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
                        ),
                        const SizedBox(height: 25),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
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
