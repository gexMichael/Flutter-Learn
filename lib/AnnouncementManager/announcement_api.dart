import './announcement_model.dart';
// 引入剛剛建立的共用服務 (請依實際路徑調整)
import '../services/generic_api_service.dart';

class AnnouncementApiService {
  // 實例化共用服務
  final GenericApiService _apiService = GenericApiService();

  Future<List<Announcement>> fetchAnnouncements() async {
    return await _apiService.fetchList<Announcement>(
      tableName: "eipbbs_m",
      pk: "uniqueno",
      queryFilter: "1^10^uniqueno^*^^eipm11^^",
      // 將 Announcement 的轉換方法傳進去
      fromJson: (json) => Announcement.fromJson(json),
    );
  }
}