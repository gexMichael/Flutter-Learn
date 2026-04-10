import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockInRecord {
  final int? clockInId;
  final String? userId; // 改為 String 以對應一般工號格式
  final DateTime? dateTime;
  final double? latitude;
  final double? longitude;
  final String? type;
  final String? storeId;
  final String? StoreName;

  ClockInRecord({
    this.clockInId,
    this.userId,
    this.dateTime,
    this.latitude,
    this.longitude,
    this.type,
    this.storeId,
    this.StoreName,
  });

  factory ClockInRecord.fromJson(Map<String, dynamic> json) {
    return ClockInRecord(
      clockInId: json['ClockInId'] as int?,
      userId: json['ClockInUserId']?.toString(),
      dateTime: json['ClockInDateTime'] != null ? DateTime.tryParse(json['ClockInDateTime']) : null,
      latitude: double.tryParse(json['ClockInLatitude']?.toString() ?? '0'),
      longitude: double.tryParse(json['ClockInLongitude']?.toString() ?? '0'),
      type: json['ClockInType'] as String?,
      storeId: json['ClockInStoreId'] as String?,
      StoreName: json['StoreName'] as String?,
    );
  }

  String get formattedTime => dateTime != null ? DateFormat('HH:mm:ss').format(dateTime!) : '--:--';
  String get formattedDate => dateTime != null ? DateFormat('yyyy-MM-dd').format(dateTime!) : 'N/A';
  // 新增：滿足列表顯示「日期 + 時間」的需求
  String get formattedDateTime => dateTime != null
      ? DateFormat('yyyy-MM-dd HH:mm').format(dateTime!)
      : 'N/A';

  Color get typeColor {
    if (type == '上班') return Colors.blue;
    if (type == '下班') return Colors.orange;
    return Colors.grey;
  }
}

class ClockInStore {
  final String storeId;
  final String storeName;
  final String? storeAddress;
  final double latitude;
  final double longitude;
  final int distance;

  ClockInStore({
    required this.storeId,
    required this.storeName,
    this.storeAddress,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });

  factory ClockInStore.fromJson(Map<String, dynamic> json) {
    return ClockInStore(
      storeId: json['StoreId'] as String? ?? '',
      storeName: json['StoreName'] as String? ?? '未知店點',
      storeAddress: json['StoreAddress'] as String?,
      // 關鍵：處理 Decimal 轉 Double
      latitude: double.tryParse(json['StoreLatitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['StoreLongitude']?.toString() ?? '0') ?? 0.0,
      distance: int.tryParse(json['Distance']?.toString() ?? '100') ?? 100,
    );
  }
}