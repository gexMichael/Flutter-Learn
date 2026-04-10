// calendar_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './calendar_model.dart';
import './calendar_api.dart';

class CalendarForm extends StatefulWidget {
  final String userId;
  final DateTime? initialDate; // 接收從行事曆首頁傳來的預設日期

  const CalendarForm({required this.userId, this.initialDate, super.key});

  @override
  State<CalendarForm> createState() => _CalendarFormState();
}

class _CalendarFormState extends State<CalendarForm> {
  final _formKey = GlobalKey<FormState>();
  final CalendarApiService _apiService = CalendarApiService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();

  String _selectedType = '會議';
  String _selectedLevel = 'NORMAL';

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 如果有傳入初始日期，就用它；否則用今天
    DateTime baseDate = widget.initialDate ?? DateTime.now();
    _startDate = baseDate;
    _endDate = baseDate;

    // 預設時間：目前時間的下一個整點，例如現在 10:25，預設 11:00 ~ 12:00
    int nextHour = TimeOfDay.now().hour + 1;
    _startTime = TimeOfDay(hour: nextHour > 23 ? 23 : nextHour, minute: 0);
    _endTime = TimeOfDay(hour: nextHour + 1 > 23 ? 23 : nextHour + 1, minute: 0);
  }

  // 結合日期與時間的選擇器
  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      if (isStart) {
        _startDate = date; _startTime = time;
        // 防呆：如果結束日期早於開始日期，自動順延
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = date; _endTime = time;
      }
    });
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // 合併 Date 與 Time 成為完整的 DateTime
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

      final newEvent = CalendarEvent(
        uuid: '', // 由後端生成
        title: _titleController.text,
        description: _descController.text,
        startTime: start,
        endTime: end,
        type: _selectedType,
        level: _selectedLevel,
        personId: widget.userId,
        projectId: _projectController.text.isNotEmpty ? _projectController.text : null,
      );

      bool success = await _apiService.createEvent(newEvent);

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('行程新增成功！')));
          Navigator.pop(context, true); // 回傳 true 通知列表刷新
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新增失敗，請檢查網路連線。', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('新增行程', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('行程標題 *', _titleController, '例如：部門月會', Icons.title, isRequired: true),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(child: _buildDropdownField('類型', _selectedType, ['會議', '拜訪客戶', '專案開發', '私人行程', '其他'], (v) => setState(() => _selectedType = v!))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildDropdownField('重要性', _selectedLevel,
                          ['URGENT', 'HIGH', 'NORMAL'],
                              (v) => setState(() => _selectedLevel = v!),
                          displayNames: {'URGENT': '緊急', 'HIGH': '高', 'NORMAL': '一般'}
                      )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('時間設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 12),
              _buildTimePickerTile('開始時間', _startDate, _startTime, true),
              const SizedBox(height: 12),
              _buildTimePickerTile('結束時間', _endDate, _endTime, false),
              const SizedBox(height: 24),

              _buildTextField('專案關聯 (選填)', _projectController, '輸入專案代號或名稱', Icons.folder_open),
              const SizedBox(height: 16),

              _buildTextField('行程詳細說明', _descController, '記錄會議大綱或行程備註...', Icons.notes, isMultiline: true),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('儲存行程', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 共用輸入框元件
  Widget _buildTextField(String label, TextEditingController controller, String hint, IconData icon, {bool isMultiline = false, bool isRequired = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiline ? 4 : 1,
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey.shade400, size: 20),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade300),
        ),
        validator: isRequired ? (v) => v == null || v.isEmpty ? '此欄位為必填' : null : null,
      ),
    );
  }

  // 共用下拉選單元件 (支援實際值與顯示名稱不同)
  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged, {Map<String, String>? displayNames}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none, labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(displayNames != null ? displayNames[s]! : s, style: const TextStyle(fontSize: 15)))).toList(),
        onChanged: onChanged,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade400),
      ),
    );
  }

  // 時間選擇按鈕元件
  Widget _buildTimePickerTile(String label, DateTime date, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _pickDateTime(isStart),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(Icons.access_time, color: isStart ? Colors.blueAccent : Colors.orangeAccent, size: 22),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 4),
                Text("${DateFormat('yyyy/MM/dd').format(date)} ${time.format(context)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            Icon(Icons.edit_calendar, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }
}