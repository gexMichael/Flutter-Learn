import './person_model.dart';
import '../services/generic_api_service.dart'; // 假設您有這個共用服務

class PersonApiService {
  final GenericApiService _apiService = GenericApiService();

  // 獲取所有人員列表，增加可選的 searchName 參數
  Future<List<Person>> fetchPeople({String? searchName}) async {
    // 預設參數：每頁 100 筆，按中文姓名排序
    String filterPart = "";

    // 如果提供了 searchName，則增加模糊查詢過濾條件
    if (searchName != null && searchName.isNotEmpty) {
      filterPart = "personcname^%$searchName%";
    }

    String vQueryfilter = "1^100^personid^*^^^$filterPart";

    return await _apiService.fetchList<Person>(
      tableName: "basperson", // 對應到 basperson 表格
      pk: "personid",          // 主鍵為 personid
      queryFilter: vQueryfilter,
      fromJson: (json) => Person.fromJson(json),
    );
  }
}