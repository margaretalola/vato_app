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
            ),
          ],
        ),
      ),
    );
  }

  void _checkIfUserHasLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLogin = prefs.getBool('hasLogin');

    if (hasLogin != null && hasLogin){
      _navigateToNextScreen();
    } else {
      await Future.delayed(const Duration(seconds: 4));
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('hasLogin', true);

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