import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

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
      home: const HomeScreen(),
    );
  }
}

// หน้าจอหลักชั่วคราวก่อนผูกระบบ AI Scanner
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCANNER BOT - AI Trading'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // แสดงโลโก้น้องนักบินอวกาศจาก Assets
            Image.asset(
              'assets/images/8.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'ยินดีต้อนรับสู่ระบบสแกนกราฟ AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'พร้อมเชื่อมต่อระบบวิเคราะห์กราฟแล้ว',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
