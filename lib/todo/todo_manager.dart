import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './todo_api.dart';
import './todo_model.dart';
import './todo_detail.dart';
import './todo_form.dart';

class TodoManager extends StatefulWidget {
  final String currentUserId;
  const TodoManager({this.currentUserId = 'admin', super.key});

  @override
  State<StatefulWidget> createState() => _TodoManagerState();
}

class _TodoManagerState extends State<TodoManager> {
  late TodoApiService _apiService;
  late Future<List<Todo>> _todosFuture;

  int _selectedDateIndex = 2; // 預設中間為「今天」
  String _selectedFilter = 'All';
  late List<DateTime> _dynamicDates;

  final Color primaryPurple = const Color(0xFF6542D0);
  final Color bgLight = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _apiService = TodoApiService(currentUserId: widget.currentUserId);
    _generateDates();
    _refreshTodos();
  }

  void _generateDates() {
    DateTime today = DateTime.now();
    // 產生 前2天 到 後2天，讓今天置中
    _dynamicDates = List.generate(5, (index) {
      return today.subtract(Duration(days: 2 - index));
    });
  }

  void _refreshTodos() {
    setState(() {
      // 根據選中的日期去後端抓資料
      _todosFuture = _apiService.fetchTodos(
          selectedDate: _dynamicDates[_selectedDateIndex]
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            _buildDateSelector(),
            _buildFilterChips(),
            Expanded(child: _buildTodoListBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 修正：加上 async 並移除 const，傳入 userId 並等待回傳結果
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TodoForm(userId: widget.currentUserId),
            ),
          );
          if (result == true) _refreshTodos();
        },
        backgroundColor: primaryPurple,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Color(0xFFF0EFFF),
        child: SizedBox(height: 60),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Tasks",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 95,
      child: Center( // 加入 Center 讓日期列表盡量置中
        child: ListView.builder(
          shrinkWrap: true, // 讓內容寬度根據子項決定
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemCount: _dynamicDates.length,
          itemBuilder: (context, index) {
            final date = _dynamicDates[index];
            final isSelected = index == _selectedDateIndex;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedDateIndex = index);
                _refreshTodos(); // 點擊連動 API 查詢
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 62,
                decoration: BoxDecoration(
                  color: isSelected ? primaryPurple : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (!isSelected)
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5)
                      )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        DateFormat('MMM').format(date),
                        style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        DateFormat('EEE').format(date),
                        style: TextStyle(color: isSelected ? Colors.white70 : Colors.grey, fontSize: 12)
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'To do', 'In Progress', 'Done'];
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedFilter == filters[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(filters[index]),
              selected: isSelected,
              onSelected: (bool selected) {
                if (selected) setState(() => _selectedFilter = filters[index]);
              },
              selectedColor: primaryPurple,
              backgroundColor: const Color(0xFFF0EFFF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : primaryPurple,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodoListBody() {
    return FutureBuilder<List<Todo>>(
      future: _todosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('載入失敗: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('此日期沒有任務，放鬆一下吧！'));
        }

        List<Todo> filtered = snapshot.data!.where((todo) {
          if (_selectedFilter == 'All') return true;
          String status = (todo.status ?? '').toUpperCase();
          if (_selectedFilter == 'Done') return status == 'DONE';
          if (_selectedFilter == 'In Progress') return status == 'WIP';
          return status != 'DONE' && status != 'WIP';
        }).toList();

        return RefreshIndicator(
          onRefresh: () async => _refreshTodos(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildTaskCard(filtered[index]),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Todo item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TodoDetail(todo: item))),
        title: Text(item.taskName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(item.className, style: const TextStyle(color: Colors.grey)),
        ),
        trailing: Icon(Icons.chevron_right, color: primaryPurple),
      ),
    );
  }
}