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
              totalRepeatCount: 1,
              onFinished: () => _navigateToNextScreen(),
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
      return;
    }

    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    User? user = FirebaseAuth.instance.currentUser;
    print('currentUser: $user');

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('hasLogin', true);
      print('Navigating to Homepage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Homepage()),
      );
    } else {
      print('Navigating to SignInPage');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInPage()),
      );
    }
  }
}