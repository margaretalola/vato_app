import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    _checkIfUserHasLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            SizedBox(height: 20),
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Make your day easier with',
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                  ),
                  speed: const Duration(milliseconds: 70), // Adjust duration
                ),
                RotateAnimatedText(
                  'VaTo App',
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                  duration: const Duration(milliseconds: 1000), // Adjust duration
                ),
              ],
              totalRepeatCount: 1,
              onFinished: () async {
                print('Animation finished');
                await Future.delayed(const Duration(seconds: 5)); // Add a longer delay
                _navigateToNextScreen();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _checkIfUserHasLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLogin = prefs.getBool('hasLogin');
    print('hasLogin: $hasLogin');

    if (hasLogin == null || !hasLogin) {
      await Future.delayed(const Duration(seconds: 2000)); // Add a longer delay
      _navigateToNextScreen();
    } else {
      _navigateToHomepage();
    }
  }

  void _navigateToNextScreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SignInPage()),
    );
  }

  void _navigateToHomepage() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
    );
  }
}