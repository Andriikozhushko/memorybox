import 'package:flutter/material.dart';

import '../pages/auth_screens/sign_in.dart'; // Adjust path as necessary

void showAuthDialog(BuildContext context, Function onContinue) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Center(
          child: Text(
            "Требуется авторизация",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
        content: const SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Center(
                child: Text(
                  "Для доступа к этому разделу необходимо войти в систему.",
                  style: TextStyle(
                    color: Color.fromRGBO(58, 58, 85, 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          const Color.fromRGBO(226, 119, 119, 1),
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'ОК',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        side: MaterialStateProperty.all(
                          const BorderSide(
                              color: Color.fromRGBO(58, 58, 85, 0.7), width: 2),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen1(),
                          ),
                        );
                        onContinue();
                      },
                      child: const Text(
                        'Войти',
                        maxLines: 1,
                        style:
                            TextStyle(color: Color.fromRGBO(58, 58, 85, 0.7)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
