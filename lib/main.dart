import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Assets/notification_screen.dart';
import 'api/firebase_api.dart';
import 'registerPage/signUp.dart';
import 'registerPage/signIn.dart';
import 'Assets/appState.dart';
import 'homepage/Homepage.dart';
import 'Assets/splashScreen/splashScreen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'default_channel_id', // id
  'Default Channel', // name
  description: 'This channel is used for important notifications.', // description
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: false);
  final firebaseOptions = FirebaseOptions(
    apiKey: dotenv.env['FIREBASE_API_KEY']!,
    appId: dotenv.env['FIREBASE_APP_ID']!,
    messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
    projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
  );

  try {
    await Firebase.initializeApp(options: firebaseOptions);
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/launcher_icon');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );

    if (await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>() != null) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()!.createNotificationChannel(channel);
    }

    await FirebaseApi().initNotifications();
    runApp(MyApp());
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
}

void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
  final String? payload = notificationResponse.payload;
  if (payload != null) {
    print('Notification payload: $payload');
    navigatorKey.currentState?.pushNamed('/notification-screen', arguments: payload);
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
      future: Future.delayed(const Duration(seconds: 3)).then((_) => _checkLoginStatus()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Splashscreen();
        } else if (snapshot.hasData && snapshot.data != null) {
          return snapshot.data ?? false ? Homepage() : SignInPage();
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final hasLogin = prefs.getBool('hasLogin') ?? false;

    if (!isLoggedIn && !hasLogin) {
      return false;
    }

    if (hasLogin) {
      return true;
    }

    final token = prefs.getString('auth_token');
    if (token == null) {
      return false;
    }

    try {
      await firebase_auth.FirebaseAuth.instance.signInWithCustomToken(token);
      prefs.setBool('hasLogin', true);
      return true;
    } catch (e) {
      print('Error signing in with custom token: $e');
      return false;
    }
  }
}