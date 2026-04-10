import 'package:flutter/material.dart';

class Person {
  final String personId;      // personid
  final String? personCName;  // personcname (中文姓名)
  final String? jobName;      // jobname (職稱)
  final String? departmentId; // departmentid (部門代號)
  final String? tel;          // tel (公司電話)
  final String? cellphone;    // cellphone (手機)
  final String? email;        // email (電子郵件)
  final String? sex;          // sex (性別)

  Person({
    required this.personId,
    this.personCName,
    this.jobName,
    this.departmentId,
    this.tel,
    this.cellphone,
    this.email,
    this.sex,
  });

  // Factory 構造函數：從 API 返回的 JSON (Map) 創建 Person 物件
  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      personId: json['personid'] as String? ?? 'N/A', //
      personCName: json['personcname'] as String?,    //
      jobName: json['jobname'] as String?,            //
      departmentId: json['departmentid'] as String?,  //
      tel: json['tel'] as String?,                    //
      cellphone: json['cellphone'] as String?,        //
      email: json['email'] as String?,                //
      sex: json['sex'] as String?,                    //
    );
  }

  // 輔助屬性：獲取性別圖示
  IconData get sexIcon {
    switch (sex?.toUpperCase()) {
      case 'M':
        return Icons.male;
      case 'F':
        return Icons.female;
      default:
        return Icons.person;
    }
  }

  // 輔助屬性：獲取性別顏色
  Color get sexColor {
    switch (sex?.toUpperCase()) {
      case 'M':
        return Colors.blue;
      case 'F':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}