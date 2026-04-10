// calendar_api.dart

import './calendar_model.dart';
import '../services/generic_api_service.dart';
import 'package:intl/intl.dart';

class CalendarApiService {
  final GenericApiService _apiService = GenericApiService();

  // 獲取指定「日期區間」的行程
  Future<List<CalendarEvent>> fetchEvents(String userId, DateTime startDate, DateTime endDate) async {
    // 格式化查詢的起迄日期
    final sDate = DateFormat('yyyy-MM-dd').format(startDate);
    // 結束日期加 1 天，用小於 (<) 來涵蓋 endDate 當天的所有時間 (23:59:59)
    final eDate = DateFormat('yyyy-MM-dd').format(endDate.add(const Duration(days: 1)));

    // 1. 組合 wheresql_org
    // 條件：大於等於開始日期，小於結束日期的隔天，且人員代號相符
    String whereSql = "start_time >= '$sDate' AND start_time < '$eDate' AND personid = '$userId'";

    // 2. 嚴格依照 API 規範組裝 10 個參數
    String queryFilter = "1^500^start_time^*^$whereSql^^^^^";

    return await _apiService.fetchList<CalendarEvent>(
      tableName: "eip_new_calendar",
      pk: "uuid",
      queryFilter: queryFilter,
      fromJson: (json) => CalendarEvent.fromJson(json),
    );
  }

  // 新增行程至資料庫
  Future<bool> createEvent(CalendarEvent event) async {
    final Map<String, dynamic> data = {
      // uuid 通常由後端資料庫生成，新增時可以不傳或傳空值
      "title": event.title,
      "cal_description": event.description,
      "start_time": event.startTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(event.startTime!) : null,
      "end_time": event.endTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(event.endTime!) : null,
      "cal_type": event.type,
      "cal_level": event.level,
      "personid": event.personId,
      "cal_finished": event.isFinished ? 'Y' : 'N',
      "projectid": event.projectId, // 關聯專案
      "create_date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    };

    try {
      // 根據 Generic API 規範，使用 action: "C" 進行新增
      await _apiService.fetchList<dynamic>(
        tableName: "eip_new_calendar",
        pk: "uuid",
        queryFilter: "",
        action: "C",
        data: data,
        fromJson: (json) => json,
      );
      return true;
    } catch (e) {
      print("Create Calendar Event Error: $e");
      return false;
    }
  }
}