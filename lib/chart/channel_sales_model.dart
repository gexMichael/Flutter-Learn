class SalesStats {
  final String channelId;
  final String channelName;
  final double sAmts;   // 對應 SQL: SUM(sales_amount) AS s_amts
  final double sQtys;   // 對應 SQL: SUM(sales_qty) AS s_qtys
  final double sProfits; // 對應 SQL: SUM(sales_profit) AS s_profits

  SalesStats({
    required this.channelId,
    required this.channelName,
    required this.sAmts,
    required this.sQtys,
    required this.sProfits,
  });

  // 從 API JSON 轉換為物件 (與 GenericApiService 配合使用)
  factory SalesStats.fromJson(Map<String, dynamic> json) {
    return SalesStats(
      channelId: json['channelid']?.toString() ?? '',
      channelName: json['channelname']?.toString() ?? '',
      // 考量到 SUM 運算後可能產生大數字或小數，統一使用 double 接收再轉型
      sAmts: double.tryParse(json['s_amts']?.toString() ?? '0') ?? 0.0,
      sQtys: double.tryParse(json['s_qtys']?.toString() ?? '0') ?? 0.0,
      sProfits: double.tryParse(json['s_profits']?.toString() ?? '0') ?? 0.0,
    );
  }

  // 將物件轉回 Map (供 UI DataTable 的 _dynamicTableData 使用)
  Map<String, dynamic> toJson() {
    return {
      'channelid': channelId,
      'channelname': channelName,
      's_amts': sAmts,
      's_qtys': sQtys,
      's_profits': sProfits,
    };
  }
}