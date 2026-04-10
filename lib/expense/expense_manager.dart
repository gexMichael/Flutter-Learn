import 'package:flutter/material.dart';
import 'expense_model.dart';
import './expense_api.dart';
import './expense_form.dart';
import './expense_detail.dart';
import 'package:intl/intl.dart';

class ExpenseManager extends StatefulWidget {
  final String currentUserId;
  const ExpenseManager({required this.currentUserId, super.key});

  @override
  State<ExpenseManager> createState() => _ExpenseManagerState();
}

class _ExpenseManagerState extends State<ExpenseManager> {
  final ExpenseApiService _apiService = ExpenseApiService();
  late Future<List<ExpenseApply>> _expenseFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _expenseFuture = _apiService.fetchExpenses(widget.currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('費用申請紀錄')),
      body: FutureBuilder<List<ExpenseApply>>(
        future: _expenseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('查無申請紀錄'));

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.blue),
                  title: Text(item.rowData ?? "無說明"),
                  subtitle: Text("金額: ${item.expAmt} | 日期: ${DateFormat('yyyy-MM-dd').format(item.applyDate)}"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseDetail(expense: item))),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_a_photo),
        label: const Text("申請費用"),
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ExpenseForm(userId: widget.currentUserId)));
          if (result == true) _refreshList();
        },
      ),
    );
  }
}