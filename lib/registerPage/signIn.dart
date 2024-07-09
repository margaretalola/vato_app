import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vato_app/registerPage/signUp.dart';
import 'package:vato_app/homepage/Homepage.dart';
import 'package:vato_app/main.dart';

class SignInPage extends StatefulWidget {
  SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  firebase_auth.FirebaseAuth firebaseAuth = firebase_auth.FirebaseAuth.instance;

  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _circular = false;
  String _errorMessage = '';

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkAuthPersistence();
  }

  void _checkAuthPersistence() async {
    firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User is signed in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Homepage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Sign In",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              SizedBox(height: 35),
              textItem('Email', _emailController, false),
              SizedBox(height: 15),
              textItem('Password', _passwordController, true),
              SizedBox(height: 20),
              loginButton(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Does not have account?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(width: 15),
                  InkWell(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (builder) => SignUpPage()),
                            (route) => false,
                      );
                    },
                    child: Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () {
                  // Implement password reset functionality here
                },
                child: Text(
                  'Forget Password?',
                  style: TextStyle(color: Colors.black, fontSize: 17),
                ),
              ),
              _errorMessage.isEmpty
                  ? Container()
                  : Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget loginButton() {
    return InkWell(
      onTap: () async {
        setState(() {
          _circular = true;
        });
        try {
          if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
            _errorMessage = 'Please fill in all fields';
            setState(() {
              _circular = false;
            });
            return;
          }
          if (!_emailController.text.contains('@') || !_emailController.text.contains('.')) {
            _errorMessage = 'Invalid email address';
            setState(() {
              _circular = false;
            });
            return;
          }
          if (_passwordController.text.length < 8) {
            _errorMessage = 'Password must be at least 8 characters long';
            setState(() {
              _circular = false;
            });
            return;
          }

          await firebase_auth.FirebaseAuth.instance
              .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

          final token = await firebase_auth.FirebaseAuth.instance.currentUser!.getIdToken();
          await UserPreferences().setAuthToken(token!);
          await UserPreferences().setLoggedIn(true);
          navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute(builder: (context) => Homepage()),
          );
        } catch (e) {
          final snackbar = SnackBar(content: Text(e.toString()));
          ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(snackbar);
          setState(() {
            _circular = false;
          });
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width - 100,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.blue,
        ),
        child: Center(
          child: _circular
              ? CircularProgressIndicator(color: Colors.white)
              : Text(
            "Login",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget textItem(String labelText, TextEditingController controller, bool obscureText) {
    return Container(
      width: MediaQuery.of(context).size.width - 70,
      height: 55,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(fontSize: 17, color: Colors.black),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            fontSize: 17,
            color: Colors.black,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              width: 1,
              color: Colors.lightBlueAccent,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              width: 1,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class UserPreferences {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _tokenKey = 'auth_token';

  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  Future<bool> get isLoggedIn async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}