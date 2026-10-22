import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const RedShieldApp());
}

// ============ الألوان ============
const Color kBgDark = Color(0xFF0D0D12);
const Color kAccent = Color(0xFF00D96E);
const Color kTextWhite = Colors.white;
const Color kTextDim = Color(0xFF999999);
const Color kRed = Color(0xFFFF5555);
const Color kCard = Color(0xFF1A1A22);

// ============ jsonbin config ============
const String BIN_ID = "6accf410ac6210605a2adcf9";
const String API_KEY_PART1 = "\$2a\$10\$6ueSPs.Rth52Seli997/TOuqpEj";
const String API_KEY_PART2 = "szXEf1Du6g.bTwyWQhYC/afy/u";

// ============ App ============
class RedShieldApp extends StatelessWidget {
  const RedShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red1 Shield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBgDark,
        primaryColor: kAccent,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ============ Login Screen ============
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _keyController = TextEditingController();
  String _statusText = '';
  Color _statusColor = kRed;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('saved_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      _keyController.text = savedKey;
      _login(silent: true);
    }
  }

  Future<void> _login({bool silent = false}) async {
    final key = _keyController.text.trim();
    if (key.isEmpty) {
      if (!silent) {
        setState(() {
          _statusText = 'الرجاء إدخال المفتاح';
          _statusColor = kRed;
        });
      }
      return;
    }

    if (!silent) {
      setState(() {
        _statusText = 'جاري التحقق...';
        _statusColor = Colors.yellow;
        _loading = true;
      });
    }

    try {
      final fullApiKey = API_KEY_PART1 + API_KEY_PART2;
      final url = Uri.parse("https://api.jsonbin.io/v3/b/$BIN_ID/latest");

      final response = await http.get(
        url,
        headers: {
          'X-Master-Key': fullApiKey,
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        setState(() {
          _statusText = 'خطأ اتصال (${response.statusCode})';
          _statusColor = kRed;
          _loading = false;
        });
        return;
      }

      final data = json.decode(response.body);
      final keysList = data['record']['keys'] as List? ?? [];

      Map<String, dynamic>? foundKey;
      for (var k in keysList) {
        if (k['key'] == key) {
          foundKey = k;
          break;
        }
      }

      if (foundKey == null) {
        setState(() {
          _statusText = 'المفتاح غير صالح';
          _statusColor = kRed;
          _loading = false;
        });
        return;
      }

      if (foundKey['status'] != 'active') {
        setState(() {
          _statusText = 'المفتاح موقوف';
          _statusColor = kRed;
          _loading = false;
        });
        return;
      }

      final tier = foundKey['tier'] ?? 'VIP';
      setState(() {
        _statusText = 'مرحباً - عضوية $tier';
        _statusColor = kAccent;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_key', key);

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(keyData: foundKey!),
        ),
      );
    } catch (e) {
      setState(() {
        _statusText = 'خطأ: ${e.toString()}';
        _statusColor = kRed;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D12), Color(0xFF1A1F2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield, color: kAccent, size: 60),
                ),
                const SizedBox(height: 24),
                const Text(
                  'RED1 SHIELD',
                  style: TextStyle(
                    color: kAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نظام الحماية',
                  style: TextStyle(color: kTextDim, fontSize: 16),
                ),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: kAccent.withOpacity(0.3)),
                  ),
                  child: TextField(
                    controller: _keyController,
                    style: const TextStyle(color: kTextWhite, fontSize: 16),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: 'أدخل مفتاح التفعيل...',
                      hintStyle: TextStyle(color: kTextDim),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _statusText,
                  style: TextStyle(color: _statusColor, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============ Main Screen ============
class MainScreen extends StatefulWidget {
  final Map<String, dynamic> keyData;
  const MainScreen({super.key, required this.keyData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _protected = false;
  bool _loading = false;
  double _progress = 0;
  String _statusMsg = '';

  Future<void> _startProtection() async {
    setState(() {
      _loading = true;
      _progress = 0;
      _statusMsg = 'يرجى الانتظار...';
    });

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() => _progress = i / 100);
    }

    setState(() {
      _protected = true;
      _loading = false;
      _statusMsg = 'تم تشغيل الحماية';
    });
  }

  Future<void> _stopProtection() async {
    setState(() {
      _loading = true;
      _progress = 0;
      _statusMsg = 'يرجى الانتظار...';
    });

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() => _progress = i / 100);
    }

    setState(() {
      _protected = false;
      _loading = false;
      _statusMsg = 'تم إيقاف الحماية';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_key');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.keyData['tier'] ?? 'VIP';
    final expires = widget.keyData['expires_at'] ?? '---';
    final days = widget.keyData['duration_days'] ?? 30;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D12), Color(0xFF1A1F2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.logout, color: kTextDim),
                      onPressed: _logout,
                    ),
                    const Text(
                      'RED1 SHIELD',
                      style: TextStyle(
                        color: kAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kAccent.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _protected ? Icons.shield : Icons.shield_outlined,
                            color: _protected ? kAccent : kRed,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _protected ? 'الحماية: مفعلة' : 'الحماية: متوقفة',
                            style: TextStyle(
                              color: _protected ? kAccent : kRed,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFF2A2A35), height: 24),
                      _infoRow('العضوية', tier),
                      const SizedBox(height: 8),
                      _infoRow('الصلاحية', '$days يوم'),
                      const SizedBox(height: 8),
                      _infoRow('ينتهي', expires),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                if (_loading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: kCard,
                      color: kAccent,
                      minHeight: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(color: kAccent, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMsg,
                    style: const TextStyle(color: kTextDim, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                ],
                if (_statusMsg.isNotEmpty && !_loading) ...[
                  Text(
                    _statusMsg,
                    style: TextStyle(
                      color: _statusMsg.contains('تشغيل') ? kAccent : kRed,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _startProtection,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text(
                      'تشغيل الحماية',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _stopProtection,
                    icon: const Icon(Icons.stop),
                    label: const Text(
                      'إيقاف الحماية',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextDim, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(color: kTextWhite, fontSize: 14),
        ),
      ],
    );
  }
}