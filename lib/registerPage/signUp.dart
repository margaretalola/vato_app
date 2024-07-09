import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vato_app/registerPage/signIn.dart';
import '../homepage/Homepage.dart';

class SignUpPage extends StatefulWidget {
  SignUpPage({Key? key}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _circular = false;
  String _errorMessage = '';

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
                "Sign Up",
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              SizedBox(height: 35),
              textItem('Email', _emailController, false),
              SizedBox(height: 15),
              textItem('Password', _passwordController, true),
              SizedBox(height: 30),
              signUpButton(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Have account?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(width: 15),
                  InkWell(
                    onTap: (){
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (builder) => SignInPage()),
                              (route) => false
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              _errorMessage.isNotEmpty
                  ? Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  Widget signUpButton() {
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
          final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );
          print(userCredential.user?.email);

          await _firestore.collection('users').doc(userCredential.user?.uid).set({
            'email': _emailController.text,
            'created_at': Timestamp.now(),
          });

          setState(() {
            _circular = false;
          });
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (builder) => Homepage()),
                (route) => false,
          );
        } catch (e) {
          _errorMessage = e.toString();
          final snackbar = SnackBar(content: Text(e.toString()));
          ScaffoldMessenger.of(context).showSnackBar(snackbar);
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
              ? CircularProgressIndicator()
              :Text(
            "Sign Up",
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
        style: TextStyle(
          fontSize: 17,
          color: Colors.black,
        ),
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