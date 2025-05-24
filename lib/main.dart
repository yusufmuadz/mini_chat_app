import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/chat_list_page_admin.dart';
import 'auth/user_auth.dart';
import 'controller/themeprovider.dart';
import 'package:provider/provider.dart';

import 'user/chat_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: FirebaseOptions(
    //   apiKey: apiKey,
    //   appId: 'mini-chat-app-e0518',
    //   messagingSenderId: messagingSenderId,
    //   projectId: projectId
    // ),
  );
  
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (for Android 13+)
  await messaging.requestPermission();

  // Dapatkan token device
  String? token = await messaging.getToken();
  print('Device FCM Token: $token');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (context) => ThemeProviderBuatan(),
    builder: (context, _) {
      final themeProvider = Provider.of<ThemeProviderBuatan>(context);

      return MaterialApp(
        title: 'Mini Chat App',
        theme: MyThemes.lightTheme,
        themeMode: themeProvider.themeMode,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!
          );
        },
        home: SplashScreen(),
      );
    }
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  void timer() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (FirebaseAuth.instance.currentUser != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? role = prefs.getString('role');
        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminChatListPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
        }
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAuth()));
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
    ));
    timer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          Icons.chat_outlined,
          size: 100,
          color: Colors.blue,
        ),
      ),
    );
  }
}
