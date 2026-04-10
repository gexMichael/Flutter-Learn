import 'package:flutter/material.dart';
import '../leave/leave_api.dart'; // 確保路徑指向你的 LeaveApiService

class PersonPickerDialog extends StatefulWidget {
  final String title;
  const PersonPickerDialog({super.key, this.title = '人員查詢'});

  @override
  State<PersonPickerDialog> createState() => _PersonPickerDialogState();
}

class _PersonPickerDialogState extends State<PersonPickerDialog> {
  final LeaveApiService _apiService = LeaveApiService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  // 執行 API 搜尋
  Future<void> _doSearch() async {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 呼叫我們先前在 leave_api 寫好的 fetchEmployees
      // 該方法會從 basperson 抓取 personid, personcname, departmentid
      final data = await _apiService.fetchEmployees(keyword);
      setState(() {
        _results = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜尋出錯: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '輸入姓名或工號',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _doSearch,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _doSearch(),
            ),
            const SizedBox(height: 15),
            if (_isLoading)
              const LinearProgressIndicator()
            else
              Flexible(
                child: _results.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('請輸入關鍵字搜尋人員', style: TextStyle(color: Colors.grey)),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final p = _results[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(p['name']), // personcname
                      subtitle: Text('工號: ${p['id']} | 部門: ${p['dept']}'),
                      onTap: () => Navigator.pop(context, p), // 回傳整筆資料
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }
}