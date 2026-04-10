import 'package:flutter/material.dart';
import 'main.dart';
import 'auth_manager.dart';
import 'auth_api.dart'; // 引入新抽離的 API Service

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController(text: '120102');
  final TextEditingController _pwdController = TextEditingController(text: 'gex123');
  final TextEditingController _compController = TextEditingController(text: 'demo');

  final AuthApiService _authApi = AuthApiService(); // 實例化 API 工具
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _logon() async {
    final String comp = _compController.text.trim();
    final String userId = _userController.text.trim();
    final String password = _pwdController.text;

    if (userId.isEmpty || password.isEmpty || comp.isEmpty) {
      setState(() => _errorMessage = '請完整填寫公司、帳號與密碼');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 呼叫封裝好的 API Service
      final responseData = await _authApi.login(
        comp: comp,
        userId: userId,
        password: password,
      );

      if (responseData['code'] == 0) {
        final List<dynamic>? dataList = responseData['data'] as List<dynamic>?;
        final String? token = (dataList != null && dataList.isNotEmpty)
            ? dataList[0]['token'] as String?
            : null;

        if (token != null) {
          // 儲存資訊至 AuthManager (包含公司別與 UserID)
          await AuthManager.saveLoginInfo(token, userId, comp);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainMenu()),
            );
          }
        } else {
          setState(() => _errorMessage = '登入成功但未取得授權碼(Token)');
        }
      } else {
        setState(() => _errorMessage = responseData['msg'] ?? '帳號或密碼錯誤');
      }
    } catch (e) {
      setState(() => _errorMessage = '系統發生異常，請聯繫管理員');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 部分保持不變，但按鈕觸發的是重構後的 _logon
    return Scaffold(
      appBar: AppBar(title: const Text('企業行動化系統')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(Icons.business_center, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 40),

              _buildTextField(_compController, '公司代號', Icons.domain),
              const SizedBox(height: 16),
              _buildTextField(_userController, '用戶帳號', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(_pwdController, '密碼', Icons.lock, obscure: true),

              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _logon,
                style: ElevatedButton.styleFrom(
                  // 修正點：使用 minimumSize 設定寬度與高度
                  // Size(double.infinity, 50) 代表寬度撐滿，高度為 50
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('登入系統', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}