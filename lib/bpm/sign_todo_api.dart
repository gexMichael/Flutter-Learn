import './sign_todo_model.dart';
import '../services/generic_api_service.dart';

class SignTodoApiService {
  final GenericApiService _apiService = GenericApiService();

  /// 1. 取得待簽核清單
  /// 對應後端 SP: [bpm_sign_todo]
  Future<List<SignTodoItem>> fetchSignTodos() async {
    // 根據 bpm_sign_todo.txt，此 SP 僅需傳入 @token
    // fetchProcedure 會自動從 AuthManager 抓取 token 並加入 body
    return await _apiService.fetchProcedure<SignTodoItem>(
      procedureEndpoint: "bpm_sign_todo",
      params: {}, // 除了 token 之外無其他參數
      fromJson: (json) => SignTodoItem.fromJson(json),
    );
  }

  /// 2. 執行簽核動作 (同意/駁回)
  /// 對應後端 SP: [bpmm02_sign_active]
  Future<bool> executeSign({
    required String type,       // @sign_type: A:同意, R:駁回
    required String uuid,       // @uuid: functionTag 或 flow_id
    required String billNo,     // @source_pk_value: 單號
    required String note,       // @sign_note: 簽核意見
    String nextSigner = '',     // @next_signer: 指定下一關簽核人 (選填)
  }) async {
    // 準備傳送給 SP 的參數 Map (不含 token，fetchProcedure 會補齊)
    final Map<String, String> params = {
      /* 配合 server 程式, 參數一律用 para0x  以方便排序 20260302 Michael
      "sign_type": type,
      "uuid": uuid,
      "source_pk_value": billNo,
      "sign_note": note,
      "next_signer": nextSigner.isEmpty ? "*" : nextSigner, // 根據 SP 註解，空值傳 *
      */
      "para01": type,
      "para02": uuid,
      "para03": billNo,
      "para04": note,
      "para05": nextSigner.isEmpty ? "*" : nextSigner, // 根據 SP 註解，空值傳 *
    };

    try {
      // 呼叫 bpmm02_sign_active
      // 註：SP 若執行成功通常回傳 code: 0，data 可能為空或執行訊息
      final result = await _apiService.fetchProcedure<dynamic>(
        procedureEndpoint: "bpmm02_sign_active",
        params: params,
        fromJson: (json) => json, // 簽核動作僅需確認 code，回傳值暫不處理
      );

      // fetchProcedure 內部若 code != 0 會回傳空清單，
      // 這裡簡單判定只要沒拋出 exception 且 code 為 0 即視為成功
      return true;
    } catch (e) {
      print("SignTodoApiService.executeSign 異常: $e");
      return false;
    }
  }
}