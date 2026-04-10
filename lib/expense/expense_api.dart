import 'dart:io';
// [修正 1] 必須導入此包才能使用 json.decode
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/generic_api_service.dart';
import '../auth_manager.dart';
import 'expense_model.dart';

class ExpenseApiService {
  final GenericApiService _apiService = GenericApiService();

  // [新增] 獲取費用類別清單 (供下拉選單使用)
  Future<List<ExpenseClass>> fetchExpenseClasses() async {
    return await _apiService.fetchList<ExpenseClass>(
      tableName: "acc_ExpClass",
      pk: "ExpId",
      queryFilter: "1^100^ExpId^*^", // 取得全部分類
      fromJson: (json) => ExpenseClass.fromJson(json),
    );
  }

  // 1. 獲取費用申請清單
  Future<List<ExpenseApply>> fetchExpenses(String empNo) async {
    // 根據 index.js 邏輯，queryFilter 應符合後端 split('^') 的期待
    String queryFilter = "1^100^ApplyDate^*^^eipm24^EmpNo^$empNo^^";
    return await _apiService.fetchList<ExpenseApply>(
      tableName: "acc_ExpsApply",
      pk: "ApplyId",
      queryFilter: queryFilter,
      fromJson: (json) => ExpenseApply.fromJson(json),
    );
  }

  // 2. 上傳照片
  /// 對接 index.js 的 upload.single('file')
  Future<String?> uploadImage(File file) async {
    try {
      // 使用 GenericApiService 內定義的 BASE_IP
      final String db = AuthManager().currentCompany ?? "demo";
      var request = http.MultipartRequest(
          'POST',
          Uri.parse("${GenericApiService.BASE_IP}/upload/eis_$db/images")
      );

      // 取得本地檔案名稱
      String picFileName = "${GenericApiService.BASE_IP}/upload/eis_$db/images/${file.path.split('/').last}";

      // [修正] index.js 的 multer 配置要求 key 必須是 'file'
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        //final Map<String, dynamic> resp = json.decode(response.body);

        // [修正] 對接 index.js: res.json({ code: 0, data: { filename: "..." } })
        /*
        final int code = resp['code'] ?? resp['Code'] ?? -1;
        if (code == 0 && resp['data'] != null) {
          return resp['data']['filename']; // 取得後端產生的新檔名
        } else {
          print("後端上傳錯誤: ${resp['msg']}");
        }
        */
        return picFileName; // 這是回傳後端產生的檔名
      }
    } catch (e) {
      print("圖片上傳異常: $e");
    }
    return null;
  }

  // 3. 提交單據
  Future<bool> submitExpense(ExpenseApply expense, String uploadedFileName) async {
    // [修正] 確保 AuthManager 的調用與專案一致
    final String? uid = AuthManager().currentUserId;
    final String currentUid = uid ?? expense.empNo;
    final String now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // 建立要存入資料庫的純字串資料 Map
    // 這些 Key 會被 index.js 的 ORM 邏輯自動轉為 SQL 欄位
    final Map<String, String> data = {
      "ApplyDate": now,
      "EmpNo": currentUid,
      "ExpId": expense.expId ?? "", // [新增] 寫入類別 ID
      "ExpAmt": expense.expAmt?.toString() ?? "0",
      "RowData": expense.rowData ?? "",
      "PicPath": uploadedFileName, // 儲存 uploadImage 回傳的檔名
      "CreatorId": currentUid,
      "CreateDateTime": now,
    };

    // 呼叫 GenericApiService
    final result = await _apiService.fetchList<ExpenseApply>(
      tableName: "acc_ExpsApply",
      pk: "ApplyId",
      queryFilter: "", // 新增單據時，filter 通常為空字串
      action: "C",      // [關鍵] 指定動作為 Create
      data: data,       // 傳遞資料
      fromJson: (json) => ExpenseApply.fromJson(json),
    );

    // 只要有回傳資料，代表資料庫 Insert 成功並回傳了該筆資料
    return result.isNotEmpty;
  }
}