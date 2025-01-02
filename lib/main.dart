import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize userId and token
  try {
    final userId = await ApiService.createAnonymousUser();
    print("User ID: $userId");
    if (userId != null) {
      final token = await ApiService.fetchToken(userId);
      if (token != null) {
        print("Token fetched successfully: $token");
      } else {
        print("Failed to fetch token.");
      }
    } else {
      print("Failed to create anonymous user.");
    }
  } catch (e) {
    print("Error initializing app: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avatar App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
