import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'auth_manager.dart';

class AuthApiService {
  static const String BASE_IP = "https://api.gex.com.tw";

  // 輔助函數：將字串轉換為 MD5
  String _generateMd5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  /// 登入 API 呼叫
  /// [comp] 公司代號
  /// [userId] 帳號
  /// [password] 原始密碼
  Future<Map<String, dynamic>> login({
    required String comp,
    required String userId,
    required String password,
  }) async {
    final String md5Password = _generateMd5(password);
    final String loginUrl = "$BASE_IP/xapi/v1/eis_${comp.trim().toLowerCase()}/checklogin/2/";

    final Map<String, String> params = {
      'token': 'xxx',
      'para01': userId,
      'para02': md5Password,
      'para03': 'web',
    };

    try {
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: params,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'code': -1, 'msg': '伺服器響應錯誤: ${response.statusCode}'};
      }
    } catch (e) {
      // return {'code': -1, 'msg': '網路連線異常'};
      print("DEBUG: API Error -> $e"); // 在 Console 看真正的錯誤類型
      return {'code': -1, 'msg': '網路連線異常: $e'};
    }
  }
}