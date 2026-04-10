// todo_form.dart (適配 Todo Model - 中文化與選項調整)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './todo_model.dart';
import './todo_api.dart';

class TodoForm extends StatefulWidget {
  final String userId;
  const TodoForm({required this.userId, super.key});

  @override
  State<TodoForm> createState() => _TodoFormState();
}

class _TodoFormState extends State<TodoForm> {
  final _formKey = GlobalKey<FormState>();
  late TodoApiService _apiService;

  // 控制器與狀態
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // 根據需求更新預設值與選項
  String _selectedClass = '工作';
  String _selectedPriority = 'Middle';
  String _selectedStatus = 'ToDo'; // 新增狀態變數
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));

  final Color primaryPurple = const Color(0xFF6542D0);
  final Color bgLight = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _apiService = TodoApiService(currentUserId: widget.userId);
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // 構建 Todo 物件
      final newTodo = Todo(
        id: 0, // 由後端生成
        taskName: _nameController.text,
        className: _selectedClass,
        description: _descController.text,
        priority: _selectedPriority,
        status: _selectedStatus, // 這裡改為帶入表單選擇的狀態
        endDate: _endDate,
        createdBy: widget.userId,
      );

      bool success = await _apiService.createTodo(newTodo);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('任務新增成功！')));
          Navigator.pop(context, true); // 回傳 true 告知列表頁刷新
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('新增失敗，請檢查網路連線。')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        title: const Text('新增任務', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 類別：改為 固定三個選項
              _buildDropdownField('任務類別', _selectedClass, ['工作', '個人行程', '其他'], (val) => setState(() => _selectedClass = val!)),
              const SizedBox(height: 20),

              // 名稱與說明：加上中文提示
              _buildTextField('任務名稱', _nameController, '例如：撰寫系統分析報告', Icons.edit_note),
              const SizedBox(height: 20),
              _buildTextField('任務說明', _descController, '請輸入任務詳細說明...', Icons.description, isMultiline: true),
              const SizedBox(height: 20),

              // 優先級：改為 High, Middle, Low
              _buildDropdownField('優先級', _selectedPriority, ['High', 'Middle', 'Low'], (val) => setState(() => _selectedPriority = val!)),
              const SizedBox(height: 20),

              // 新增狀態下拉選單
              _buildDropdownField('目前狀態', _selectedStatus, ['ToDo', 'WIP', 'Hold', 'Done'], (val) => setState(() => _selectedStatus = val!)),
              const SizedBox(height: 20),

              _buildDatePicker('截止日期', _endDate),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- 重構後的 UI 元件 ---

  Widget _buildTextField(String label, TextEditingController controller, String hint, IconData icon, {bool isMultiline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          TextFormField(
            controller: controller,
            maxLines: isMultiline ? 3 : 1,
            decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.only(top: 8)),
            validator: (v) => v == null || v.isEmpty ? '此欄位不能為空' : null, // 必填防呆中文化
          )
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 14, color: Colors.grey), border: InputBorder.none),
          items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime date) {
    return InkWell(
      onTap: _selectEndDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                // 日期格式也順便調整成台灣習慣的 YYYY/MM/DD
                Text(DateFormat('yyyy/MM/dd').format(date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Icon(Icons.calendar_today, color: primaryPurple, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5),
        onPressed: _handleSubmit,
        child: const Text('建立任務', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}