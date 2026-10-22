import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:firebase_database/firebase_database.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _imageFile;
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  
  // Firebase Database Reference สำหรับเก็บประวัติการสแกน
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('scan_history');

  // 🔑 ใส่ Gemini API Key ของพี่ตรงนี้
  final String _apiKey = 'YOUR_GEMINI_API_KEY';

  // ฟังก์ชันเลือกรูปภาพจากคลังภาพ หรือ ถ่ายภาพ
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 85, // บีบอัดภาพให้ส่งประมวลผลได้รวดเร็วขึ้น
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _analysisResult = null;
      });
      _analyzeChart();
    }
  }

  // ฟังก์ชันส่งภาพกราฟไปวิเคราะห์ด้วย Gemini AI
  Future<void> _analyzeChart() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash', // ใช้โมเดลประมวลผลภาพที่รวดเร็ว
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json', // บังคับให้ AI ตอบกลับมาเป็น JSON เสมอ
        ),
      );

      final imageBytes = await _imageFile!.readAsBytes();
      
      const prompt = '''
คุณคือนักวิเคราะห์เทคนิคระดับมืออาชีพ โปรดวิเคราะห์ภาพกราฟนี้ และตอบกลับเป็น JSON เท่านั้น โดยมีโครงสร้างดังนี้:
{
  "trend": "Bullish / Bearish / Sideway",
  "signal": "Buy / Sell / Neutral",
  "entry_zone": "ช่วงราคาที่เหมาะสม",
  "stop_loss": "จุดตัดขาดทุน",
  "take_profit": "จุดทำกำไร",
  "reasoning": [
    "เหตุผลข้อที่ 1",
    "เหตุผลข้อที่ 2",
    "เหตุผลข้อที่ 3"
  ]
}
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      
      if (response.text != null) {
        final jsonResult = jsonDecode(response.text!) as Map<String, dynamic>;
        
        setState(() {
          _analysisResult = jsonResult;
          _isLoading = false;
        });

        // บันทึกผลลัพธ์ลง Firebase Realtime Database
        _saveToFirebase(jsonResult);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  // บันทึกประวัติลง Firebase
  Future<void> _saveToFirebase(Map<String, dynamic> data) async {
    try {
      await _dbRef.push().set({
        ...data,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Firebase Save Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text('SCANNER BOT - AI Analysis'),
        backgroundColor: const Color(0xFF161616),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ส่วนแสดงรูปภาพกราฟ
            Container(
              height: 260,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, fit: BoxFit.contain),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/8.jpg', width: 64, height: 64),
                        const SizedBox(height: 12),
                        const Text('เลือกหรือถ่ายภาพหน้าจอกราฟเพื่อสแกน', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // ปุ่มเลือกรูปจากคลัง & ถ่ายภาพ
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('คลังภาพ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF2C2C2C),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ถ่ายภาพ'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFE50914),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ส่วนแสดงผลลัพธ์การวิเคราะห์
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.redAccent),
                    SizedBox(height: 16),
                    Text('AI กำลังแกะรอยและสแกนกราฟ...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else if (_analysisResult != null)
              CyberNeonResultBox(result: _analysisResult!),
          ],
        ),
      ),
    );
  }
}

// Widget กล่องไซเบอร์พังค์ขอบเรืองแสงพร้อมเอฟเฟกต์พิมพ์ดีด
class CyberNeonResultBox extends StatefulWidget {
  final Map<String, dynamic> result;
  const CyberNeonResultBox({super.key, required this.result});

  @override
  State<CyberNeonResultBox> createState() => _CyberNeonResultBoxState();
}

class _CyberNeonResultBoxState extends State<CyberNeonResultBox> with SingleTickerProviderStateMixin {
  String _displayedText = '';
  int _currentIndex = 0;
  late String _fullText;
  bool _isTypingComplete = false;

  @override
  void initState() {
    super.initState();
    final signal = widget.result['signal'] ?? 'Neutral';
    final trend = widget.result['trend'] ?? '-';
    final entry = widget.result['entry_zone'] ?? '-';
    final sl = widget.result['stop_loss'] ?? '-';
    final tp = widget.result['take_profit'] ?? '-';
    
    List reasons = widget.result['reasoning'] ?? [];
    String reasonText = reasons.map((r) => '• $r').join('\n');

    // จัดรูปแบบข้อความที่จะให้พิมพ์ดีดโชว์
    _fullText = "> SIGNAL: $signal\n> TREND: $trend\n> ENTRY ZONE: $entry\n> STOP LOSS: $sl\n> TAKE PROFIT: $tp\n\n[ANALYSIS REASONING]:\n$reasonText";
    
    _startTypingEffect();
  }

  void _startTypingEffect() {
    Future.delayed(const Duration(milliseconds: 30), () {
      if (_currentIndex < _fullText.length && mounted) {
        setState(() {
          _displayedText += _fullText[_currentIndex];
          _currentIndex++;
        });
        _startTypingEffect();
      } else {
        setState(() {
          _isTypingComplete = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final signal = widget.result['signal'] ?? 'Neutral';
    Color signalColor = Colors.grey;
    if (signal.toString().toUpperCase() == 'BUY') signalColor = Colors.greenAccent;
    if (signal.toString().toUpperCase() == 'SELL') signalColor = Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'AI SCANNER TERMINAL',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: signalColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: signalColor),
                ),
                child: Text(
                  signal.toString().toUpperCase(),
                  style: TextStyle(color: signalColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.redAccent),
          // แสดงผลแบบพิมพ์ดีดฟอนต์โมโนสเปซ
          Text(
            _displayedText,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (!_isTypingComplete)
            const Text(
              '▋',
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
        ],
      ),
    );
  }
}
