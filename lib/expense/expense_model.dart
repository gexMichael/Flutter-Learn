// 在 expense_model.dart 中修改
import '../auth_manager.dart';
import '../services/generic_api_service.dart';

// --- 新增類別模型 ---
class ExpenseClass {
  final String expId;
  final String? expCName;
  final String? expDesc;

  ExpenseClass({required this.expId, this.expCName, this.expDesc});

  factory ExpenseClass.fromJson(Map<String, dynamic> json) {
    return ExpenseClass(
      expId: json['ExpId'] ?? '',
      expCName: json['ExpCName'],
      expDesc: json['Exp_Desc'],
    );
  }
}

class ExpenseApply {
  final int? applyId;
  final DateTime applyDate;
  final String empNo;
  final String? personCName; // new
  final String? rowData;    // 費用說明
  final String? picPath;    // 圖片檔名/路徑
  final String? expId;      // [新增] 類別 ID
  final String? expCName;   // [新增] 類別名稱 (供查詢顯示用)
  final int? expAmt;     // [新增] 費用金額
  final String? creatorId;
  final DateTime? createDateTime;

  // [修改] 動態取得完整網址的 Getter
  String get fullPicUrl {
    if (picPath == null || picPath!.trim().isEmpty) return "";

    // 1. 先去除前後空白，避免不可見字元的干擾
    String path = picPath!.trim();

    // 2. 判斷是否已經是完整網址 (http/https)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // 3. 【關鍵修正】檢查 path 開頭是否有斜線，如果有，把它去掉
    // 避免與前面的 "/images/" 組成 "//" 導致解析異常
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // 4. 取得目前登入的公司別
    final String db = AuthManager().currentCompany ?? "demo";

    // 5. 組合最終網址
    return "${GenericApiService.BASE_IP}/upload/eis_$db/images/$path";
  }

  ExpenseApply({
    this.applyId,
    required this.applyDate,
    required this.empNo,
    this.personCName,  //關聯擴充欄位
    this.rowData,
    this.picPath,
    this.expId,
    this.expCName,
    this.expAmt,
    this.creatorId,
    this.createDateTime,
  });

  factory ExpenseApply.fromJson(Map<String, dynamic> json) {
    return ExpenseApply(
      applyId: int.tryParse(json['ApplyId']?.toString() ?? ''),
      applyDate: json['ApplyDate'] != null ? DateTime.parse(json['ApplyDate']) : DateTime.now(),
      empNo: json['EmpNo'] as String? ?? '',
      personCName: json['personCName'] as String? ?? '',  // new
      rowData: json['RowData'] as String?,
      picPath: json['PicPath'] as String?,
      expId: json['ExpId'] as String? ?? '',       // [新增]
      expCName: json['ExpCName'] as String? ?? '', // [新增] 假設後端透過 View 聯集查詢
      expAmt: int.tryParse(json['ExpAmt']?.toString() ?? '0') ?? 0,
      creatorId: json['CreatorId'] as String?,
      createDateTime: json['CreateDateTime'] != null ? DateTime.parse(json['CreateDateTime']) : null,
    );
  }

  // 輔助屬性：取得完整圖片路徑 (假設後端基礎 URL)
  // String get fullPicUrl => "https://api.gex.com.tw:8033/uploads/$picPath";
}