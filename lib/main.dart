import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:provider/provider.dart';
import 'package:vato_app/Assets/notification_screen.dart';
import 'package:vato_app/api/firebase_api.dart';
import 'package:vato_app/registerPage/signUp.dart';
import 'package:vato_app/registerPage/signIn.dart';
import 'Assets/appState.dart';
import 'homepage/Homepage.dart';
import 'package:vato_app/Assets/splashScreen/splashScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final envFile = File(join(dirname(Platform.script.toFilePath()), '.env'));

final navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel_id', // id
  'Default Channel', // name
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env', isOptional: false);
    final firebaseOptions = FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    );
    await Firebase.initializeApp(options: firebaseOptions);
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // Initialize notification channel for Android
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseApi().initNotifications();
    runApp(MyApp());
  } catch (e) {
    print('Error loading .env file: $e');
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Vato App',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        home: AuthenticationWrapper(),
        routes: {
          '/home': (context) => Homepage(),
          '/signIn': (context) => SignInPage(),
          '/signUp': (context) => SignUpPage(),
          '/notification-screen': (context) => NotificationScreen(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Splashscreen();
        } else if (snapshot.hasData && snapshot.data == true) {
          return Homepage();
        } else {
          return SignInPage();
        }
      },
    );
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (!isLoggedIn) {
      return false;
    }

    final token = prefs.getString('auth_token');
    if (token == null) {
      return false;
    }

    try {
      await firebase_auth.FirebaseAuth.instance.signInWithCustomToken(token);
      return true;
    } catch (e) {
      print('Error signing in with custom token: $e');
      return false;
    }
  }
}
