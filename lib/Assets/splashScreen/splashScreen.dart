import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vato_app/homepage/Homepage.dart';
import 'package:vato_app/registerPage/signIn.dart';

class Splashscreen extends StatefulWidget {
  @override
  State<Splashscreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<Splashscreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Make your day easier with',
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                  ),
                  speed: const Duration(milliseconds: 50),
                ),
                RotateAnimatedText(
                  'VaTo App',
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 4));
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    }
  }
}