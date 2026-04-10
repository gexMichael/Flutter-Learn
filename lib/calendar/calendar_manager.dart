// calendar_manager.dart

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import './calendar_model.dart';
import './calendar_api.dart';
import './calendar_detail.dart';
import './calendar_form.dart';

class CalendarManager extends StatefulWidget {
  final String userId;
  const CalendarManager({required this.userId, super.key});

  @override
  State<CalendarManager> createState() => _CalendarManagerState();
}

class _CalendarManagerState extends State<CalendarManager> {
  final CalendarApiService _apiService = CalendarApiService();

  // ==== 日曆模式狀態 ====
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _eventsMap = {}; // 供日曆標點使用

  // ==== 列表模式狀態 ====
  late DateTime _listStartDate;
  late DateTime _listEndDate;
  List<CalendarEvent> _listEvents = []; // 供列表模式獨立顯示使用

  // 控制目前是日曆還是列表
  String _viewMode = '日曆模式';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // 初始化列表模式的預設區間為「本月 1 日」到「本月底」
    _listStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _listEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

    // 預設載入日曆資料
    _fetchMonthEvents(_focusedDay);
  }

  // ============== API 抓取邏輯 ==============

  // 1. 日曆模式：抓取整個月並轉換為 Map 標點
  Future<void> _fetchMonthEvents(DateTime month) async {
    setState(() => _isLoading = true);
    try {
      final sDate = DateTime(month.year, month.month, 1);
      final eDate = DateTime(month.year, month.month + 1, 0); // 當月最後一天
      final events = await _apiService.fetchEvents(widget.userId, sDate, eDate);

      Map<DateTime, List<CalendarEvent>> newMap = {};
      for (var event in events) {
        if (event.startTime != null) {
          final dateKey = DateTime(event.startTime!.year, event.startTime!.month, event.startTime!.day);
          if (newMap[dateKey] == null) newMap[dateKey] = [];
          newMap[dateKey]!.add(event);
        }
      }

      setState(() {
        _eventsMap = newMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("載入失敗: $e")));
    }
  }

  // 2. 列表模式：抓取特定日期區間，單純存成 List
  Future<void> _fetchListEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _apiService.fetchEvents(widget.userId, _listStartDate, _listEndDate);

      // 依開始時間排序
      events.sort((a, b) => (a.startTime ?? DateTime.now()).compareTo(b.startTime ?? DateTime.now()));

      setState(() {
        _listEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("列表載入失敗: $e")));
    }
  }

  // 簡單式：獨立選擇開始或結束日期
  Future<void> _selectDate(bool isStart) async {
    final DateTime initialDate = isStart ? _listStartDate : _listEndDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blueAccent),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _listStartDate = picked;
          // 防呆：如果開始日期大於結束日期，讓結束日期自動等於開始日期
          if (_listStartDate.isAfter(_listEndDate)) {
            _listEndDate = _listStartDate;
          }
        } else {
          _listEndDate = picked;
          // 防呆：如果結束日期小於開始日期，讓開始日期自動等於結束日期
          if (_listEndDate.isBefore(_listStartDate)) {
            _listStartDate = _listEndDate;
          }
        }
      });
      _fetchListEvents(); // 選定後立刻觸發 API 重新查詢
    }
  }

  // 獲取日曆選定日期的行程
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _eventsMap[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('行事曆', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          // 視圖切換下拉選單
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _viewMode,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                items: ['日曆模式', '列表模式'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null && newValue != _viewMode) {
                    setState(() => _viewMode = newValue);
                    // 切換模式時，呼叫對應的 API
                    if (newValue == '列表模式') {
                      _fetchListEvents();
                    } else {
                      _fetchMonthEvents(_focusedDay);
                    }
                  }
                },
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.today, color: Colors.blueAccent),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();

                  // 如果是列表模式，也順便重置回當月區間
                  _listStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
                  _listEndDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
                });

                _viewMode == '日曆模式'
                    ? _fetchMonthEvents(_focusedDay)
                    : _fetchListEvents();
              }
          ),
        ],
      ),
      body: _viewMode == '日曆模式' ? _buildCalendarLayout() : _buildListLayout(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          // 跳轉至新增表單，並將目前選擇的日期傳入作為預設值
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CalendarForm(
                userId: widget.userId,
                initialDate: _selectedDay, // 貼心設計：自動帶入你在日曆上點擊的日期
              ),
            ),
          );

          // 如果表單回傳 true (代表新增成功)，就重新 Call API 抓取最新資料！
          if (result == true) {
            if (_viewMode == '日曆模式') {
              _fetchMonthEvents(_focusedDay);
            } else {
              _fetchListEvents();
            }
          }
        },
      ),
    );
  }

  // ============== 視圖 1：日曆模式 ==============
  Widget _buildCalendarLayout() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              markerDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _fetchMonthEvents(focusedDay);
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildEventListForDay(),
        ),
      ],
    );
  }

  Widget _buildEventListForDay() {
    final dayEvents = _getEventsForDay(_selectedDay!);

    if (dayEvents.isEmpty) {
      return Center(
        child: Text("${DateFormat('MM/dd').format(_selectedDay!)} 沒有行程", style: const TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) => _buildEventCard(dayEvents[index]),
    );
  }

  // ============== 視圖 2：列表模式 (簡單式日期篩選器) ==============
  Widget _buildListLayout() {
    return Column(
      children: [
        // 頂部日期區間選擇器 (簡單式左右分割)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(child: _buildDateSelectButton('開始日期', _listStartDate, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('至', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildDateSelectButton('結束日期', _listEndDate, false)),
            ],
          ),
        ),

        // 列表結果
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _listEvents.isEmpty
              ? const Center(child: Text("該區間尚無任何行程", style: TextStyle(color: Colors.grey, fontSize: 16)))
              : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _listEvents.length,
            itemBuilder: (context, index) {
              return _buildEventCard(_listEvents[index], showDate: true);
            },
          ),
        ),
      ],
    );
  }

  // 獨立的日期選擇按鈕 UI
  Widget _buildDateSelectButton(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () => _selectDate(isStart),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.05),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.blueAccent),
                const SizedBox(width: 6),
                Text(
                    DateFormat('yyyy/MM/dd').format(date),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 14)
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============== 共用元件：行程 Card ==============
  Widget _buildEventCard(CalendarEvent event, {bool showDate = false}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 5,
          height: 40,
          decoration: BoxDecoration(
            color: event.levelColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                showDate && event.startTime != null
                    ? "${DateFormat('MM/dd').format(event.startTime!)}  ${event.timeRangeText}"
                    : event.timeRangeText,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CalendarDetail(event: event))
        ),
      ),
    );
  }
}