import 'package:flutter/material.dart';
import './leave_model.dart';
import './leave_api.dart';
import 'package:intl/intl.dart';
import '../services/person_picker_dialog.dart';

class LeaveForm extends StatefulWidget {
  final String userId;
  const LeaveForm({required this.userId, super.key});

  @override
  State<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final LeaveApiService _leaveApi = LeaveApiService();

  // 狀態變數
  List<LeaveType> _dbLeaveTypes = [];
  LeaveType? _selectedType;
  bool _isLoadingTypes = true;

  Map<String, dynamic>? _selectedAgent;   // 改為這個
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 09, minute: 00);
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 00);
  String _note = '';

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time == null) return;

    setState(() {
      if (isStart) {
        _startDate = date; _startTime = time;
      } else {
        _endDate = date; _endTime = time;
      }
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate() && _selectedType != null && _selectedAgent != null) {
      _formKey.currentState!.save();

      // 合併日期時間
      final start = DateTime(_startDate.year, _startDate.month, _startDate.day, _startTime.hour, _startTime.minute);
      final end = DateTime(_endDate.year, _endDate.month, _endDate.day, _endTime.hour, _endTime.minute);

      // 檢查結束時間是否大於開始時間
      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('結束時間必須大於開始時間')));
        return;
      }

      // 修正 2: 自動推算天數與小時 (簡易版：假設一天 8 小時工作制)
      final duration = end.difference(start);
      final double totalHours = duration.inMinutes / 60.0;
      final double calcDays = (totalHours / 8).floorToDouble();
      final double calcHours = totalHours % 8;

      final newLeave = Leave(
        billNo: '', // API 端生成
        personId: widget.userId,
        agentId: _selectedAgent!['id'].toString(), // 確保轉為 String
        agentName: '',
        leaveType: _selectedType!.id, // 傳送 ID 給後端
        leaveTypeName: '',
        startTime: start,
        endTime: end,
        days: calcDays,   // 寫入計算後的天數
        hours: calcHours, // 寫入計算後的小時
        leaveNote: _note,
      );

      await LeaveApiService().createLeave(newLeave);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 從 API 載入假別
  Future<void> _loadInitialData() async {
    try {
      final types = await _leaveApi.fetchLeaveTypes();
      setState(() {
        _dbLeaveTypes = types;
        // 預設選取第一筆（如有資料）
        if (_dbLeaveTypes.isNotEmpty) {
          _selectedType = _dbLeaveTypes.first;
        }
        _isLoadingTypes = false;
      });
    } catch (e) {
      setState(() => _isLoadingTypes = false);
      // 實務上應加入錯誤處理提示
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增請假申請')),
      body: _isLoadingTypes
          ? const Center(child: CircularProgressIndicator()) // 載入中顯示轉圈
        :Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 假別選擇 (顯示名稱，存入代碼)
            DropdownButtonFormField<LeaveType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: '請假類別', border: OutlineInputBorder()),
              // 將 API 取得的資料轉換為選單項目
              items: _dbLeaveTypes.map((t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.name) // 顯示 leavetype_name
              )).toList(),
              onChanged: (v) => setState(() => _selectedType = v),
              validator: (v) => v == null ? '請選擇假別' : null,
            ),
            const SizedBox(height: 16),
            // 代理人開窗
            // 在 _LeaveFormState 內部的 Widget Tree 中
            ListTile(
              title: const Text('代理人'),
              // 顯示已選擇的代理人姓名與 ID，若無則顯示提示
              subtitle: Text(_selectedAgent == null
                  ? '請點擊選擇代理人'
                  : '${_selectedAgent!['name']} (${_selectedAgent!['id']})'),
              trailing: const Icon(Icons.person_add_alt_1, color: Colors.blue),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () async {
                // 呼叫獨立的彈窗組件
                final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => const PersonPickerDialog(title: '查詢代理人'),
                );

                // 如果使用者有選取人員（result 不為 null），則更新 UI 狀態
                if (result != null) {
                  setState(() {
                    _selectedAgent = result;
                    // 這裡 result 的內容為 {'id': '...', 'name': '...', 'dept': '...'}
                  });
                }
              },
            ),

            const SizedBox(height: 16),
            // 起訖時間選擇區
            _buildTimePickerTile('開始時間', _startDate, _startTime, true),
            const SizedBox(height: 10),
            _buildTimePickerTile('結束時間', _endDate, _endTime, false),

            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: '事由說明'),
              maxLines: 3,
              onSaved: (v) => _note = v!,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('提交申請'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerTile(String label, DateTime date, TimeOfDay time, bool isStart) {
    final format = DateFormat('yyyy/MM/dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.blueGrey)),
        const SizedBox(height: 5),
        InkWell(
          onTap: () => _pickDateTime(isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.blue),
                const SizedBox(width: 10),
                Text('${format.format(date)}  ${time.format(context)}', style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}