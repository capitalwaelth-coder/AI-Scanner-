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
      appBar: AppBar(
        title: const Text('SCANNER BOT - AI Analysis'),
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
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_imageFile!, fit: BoxFit.contain),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/8.png', width: 64, height: 64),
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
                      backgroundColor: const Color(0xFF2196F3),
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
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI กำลังแกะรอยและสแกนกราฟ...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else if (_analysisResult != null)
              _buildResultCard(_analysisResult!),
          ],
        ),
      ),
    );
  }

  // การ์ดแสดงผลลัพธ์การวิเคราะห์
  Widget _buildResultCard(Map<String, dynamic> result) {
    final signal = result['signal'] ?? 'Neutral';
    Color signalColor = Colors.grey;
    if (signal.toString().toUpperCase() == 'BUY') signalColor = Colors.green;
    if (signal.toString().toUpperCase() == 'SELL') signalColor = Colors.red;

    return Card(
      elevation: 4,
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Signal: $signal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: signalColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Trend: ${result['trend'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.grey),
            _buildInfoRow('Entry Zone', result['entry_zone'] ?? '-'),
            _buildInfoRow('Stop Loss', result['stop_loss'] ?? '-', color: Colors.redAccent),
            _buildInfoRow('Take Profit', result['take_profit'] ?? '-', color: Colors.greenAccent),
            const SizedBox(height: 16),
            const Text('เหตุผลการวิเคราะห์:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...?((result['reasoning'] as List?)?.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(color: Colors.blue)),
                      Expanded(child: Text(r.toString(), style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                ))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.white)),
        ],
      ),
    );
  }
}
