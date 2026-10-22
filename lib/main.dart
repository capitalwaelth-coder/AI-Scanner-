import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'scanner_screen.dart'; // นำเข้าหน้าจอ ScannerScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ล็อกหน้าจอให้เป็นแนวตั้ง
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // เริ่มต้นใช้งาน Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const ScannerBotApp());
}

class ScannerBotApp extends StatelessWidget {
  const ScannerBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCANNER BOT',
      debugShowCheckedModeBanner: false,
      // ธีมสีมืดสไตล์เทรดเดอร์ (Dark Mode)
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF2196F3),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      // กำหนดให้เปิดแอปมาเจอหน้าจอสแกนกราฟ AI ทันที
      home: const ScannerScreen(),
    );
  }
}
