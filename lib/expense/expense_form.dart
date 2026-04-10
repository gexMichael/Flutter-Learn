import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './expense_api.dart';
import 'expense_model.dart';
import '../services/ui_utils.dart';

class ExpenseForm extends StatefulWidget {
  final String userId;
  const ExpenseForm({required this.userId, super.key});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ExpenseApiService();
  final _descController = TextEditingController();
  final _amtController = TextEditingController(); // [新增] 金額控制器

  File? _image;
  bool _isSubmitting = false;
  // New
  String? _selectedExpId;
  List<ExpenseClass> _classList = [];
  bool _isLoadingClass = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  // 讀取分類資料
  void _loadClasses() async {
    final list = await _apiService.fetchExpenseClasses();
    setState(() {
      _classList = list;
      _isLoadingClass = false;
    });
  }

  // 啟動相機
  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _submit() async {
    // 1. 基本驗證
    if (!_formKey.currentState!.validate() || _image == null) {
      UiUtils.showMsg(context, "請輸入說明並拍攝單據", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 2. 第一步：上傳照片
      String? fileName = await _apiService.uploadImage(_image!);

      if (fileName == null) {
        if (mounted) UiUtils.showMsg(context, "圖片上傳失敗，請檢查網路連接", isError: true);
        setState(() => _isSubmitting = false);
        return;
      }

      // 3. 第二步：提交資料表紀錄
      final newExpense = ExpenseApply(
        applyDate: DateTime.now(),
        empNo: widget.userId,
        rowData: _descController.text,
        expId: _selectedExpId,
        expAmt: int.tryParse(_amtController.text),
      );

      // 這裡會呼叫 fetchList，如果上面 GenericApiService 修正了，這裡就會回傳 true
      bool success = await _apiService.submitExpense(newExpense, fileName);

      if (success) {
        if (mounted) {
          UiUtils.showMsg(context, "申請成功！");
          // 延遲一小段時間讓使用者看到訊息再關閉，或直接關閉
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      } else {
        if (mounted) UiUtils.showMsg(context, "資料寫入失敗，請確認伺服器回應", isError: true);
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) UiUtils.showMsg(context, "發生非預期錯誤: $e", isError: true);
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新增費用申請')),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _image == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.camera_alt, size: 50), Text("點擊拍照收據")],
                  )
                      : Image.file(_image!, fit: BoxFit.cover),
                ),
              ),
              // [新增] 類別下拉選單
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedExpId,
                decoration: const InputDecoration(labelText: "費用類別", border: OutlineInputBorder()),
                items: _classList.map((c) => DropdownMenuItem(
                  value: c.expId,
                  child: Text(c.expCName ?? c.expId),
                )).toList(),
                onChanged: (val) => setState(() => _selectedExpId = val),
                validator: (v) => v == null ? "請選擇類別" : null,
              ),
              const SizedBox(height: 16),
              // 2. [新增] 金額輸入框
              TextFormField(
                controller: _amtController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "費用金額 (ExpAmt)",
                  prefixText: "",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "請輸入金額";
                  if (double.tryParse(v) == null) return "請輸入有效的數字";
                  if (double.parse(v) <= 0) return "金額必須大於 0";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "費用說明 (RowData)", border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "必填" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("提交申請"),
              )
            ],
          ),
        ),
      ),
    );
  }
}