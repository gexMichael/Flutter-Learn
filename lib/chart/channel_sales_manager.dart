import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import './channel_sales_api.dart';
import './channel_sales_model.dart';

class ChannelSalesManager extends StatefulWidget {
  const ChannelSalesManager({super.key});

  @override
  State<ChannelSalesManager> createState() => _ChannelSalesManagerState();
}

class _ChannelSalesManagerState extends State<ChannelSalesManager> {
  final SalesStatisticsService _service = SalesStatisticsService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "en_US");
  final TextEditingController _channelController = TextEditingController();

  // 狀態變數：月份區間與資料儲存
  String _startYYMM = "${DateTime.now().year}01";
  String _endYYMM = DateFormat('yyyyMM').format(DateTime.now());

  // 儲存一般查詢的 Future
  late Future<List<SalesStats>> _statsFuture;

  // 儲存進階分析 (SP) 的原始 Model 數據與表格數據
  List<SalesStats> _chartData = [];
  List<Map<String, dynamic>> _dynamicTableData = [];

  @override
  void initState() {
    super.initState();
    _doSearch(); // 初始載入一般數據
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  // 動作 1：標準搜尋 (ORM API)
  void _doSearch() {
    setState(() {
      _chartData = []; // 清空 SP 數據以顯示一般圖表
      _dynamicTableData = [];
      _statsFuture = _service.getChannelStats(
        startYYMM: _startYYMM,
        endYYMM: _endYYMM,
        channelId: _channelController.text,
      );
    });
  }

  // 動作 2：進階分析 (Stored Procedure)
  Future<void> _runAdvancedSP() async {
    try {
      final List<SalesStats> result = await _service.executeSP(
        endpoint: "sp_get_channel_sales_stats",
        p_01: _channelController.text.isEmpty ? "*" : _channelController.text,
        p_02: _startYYMM,
        p_03: _endYYMM,
      );

      setState(() {
        _chartData = result; // 更新圖表數據
        _dynamicTableData = result.map((item) => item.toJson()).toList(); // 更新表格
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('進階分析執行失敗: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('通路銷售分析')),
      body: Column(
        children: [
          _buildSearchPanel(), // 包含月份選擇與搜尋
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _doSearch(),
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  // 根據是否有進階分析數據切換視圖
  Widget _buildMainContent() {
    if (_chartData.isNotEmpty) {
      // 如果有進階分析結果，顯示圖表與表格
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryCards(_chartData),
            const SizedBox(height: 20),
            _buildTrendChart(_chartData),
            const SizedBox(height: 20),
            _buildRegionPieChart(_chartData),
            const SizedBox(height: 20),
            _buildDynamicDataTable(), // 底部顯示資料明細
          ],
        ),
      );
    } else {
      // 顯示一般搜尋的 FutureBuilder
      return _buildDashboardCharts();
    }
  }

  // 搜尋面板：整合月份選擇與按鈕
  Widget _buildSearchPanel() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                _buildDateButton("開始: $_startYYMM", true),
                const SizedBox(width: 8),
                _buildDateButton("結束: $_endYYMM", false),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _channelController,
                    decoration: const InputDecoration(
                      hintText: '輸入通路 ID (留空則搜尋全部)',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(icon: const Icon(Icons.search), onPressed: _doSearch),
                IconButton.filled(
                  icon: const Icon(Icons.insights),
                  onPressed: _runAdvancedSP,
                  style: IconButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String text, bool isStart) {
    return Expanded(
      child: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month, size: 18),
        label: Text(text),
        onPressed: () async {
          String? picked = await _showMonthPicker(context, isStart ? _startYYMM : _endYYMM);
          if (picked != null) {
            setState(() {
              if (isStart) {
                _startYYMM = picked;
              } else {
                _endYYMM = picked;
              }
            });
          }
        },
      ),
    );
  }

  // 圖表組件：銷售趨勢 (LineChart)
  Widget _buildTrendChart(List<SalesStats> data) {
    if (data.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(" 銷售金額分析", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      int idx = value.toInt();
                      if (idx >= 0 && idx < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(data[idx].channelId, style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.sAmts)).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 圖表組件：佔比 (PieChart)
  Widget _buildRegionPieChart(List<SalesStats> data) {
    if (data.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(" 銷售分配", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: data.asMap().entries.map((e) {
                return PieChartSectionData(
                  value: e.value.sAmts,
                  title: e.value.channelName,
                  radius: 50,
                  color: Colors.primaries[e.key % Colors.primaries.length],
                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // 顯示 SP 結果表格
  Widget _buildDynamicDataTable() {
    if (_dynamicTableData.isEmpty) return const SizedBox();
    List<String> columns = _dynamicTableData.first.keys.toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(" 資料明細", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton(onPressed: () => setState(() => _chartData = []), child: const Text("關閉分析")),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns.map((col) => DataColumn(label: Text(col.toUpperCase()))).toList(),
            rows: _dynamicTableData.map((row) {
              return DataRow(cells: columns.map((col) => DataCell(Text(row[col]?.toString() ?? ''))).toList());
            }).toList(),
          ),
        ),
      ],
    );
  }

  // 原有的 Dashboard 內容
  Widget _buildDashboardCharts() {
    return FutureBuilder<List<SalesStats>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text("載入失敗: ${snapshot.error}"));
        final data = snapshot.data ?? [];
        if (data.isEmpty) return const Center(child: Text("此區間無資料"));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSummaryCards(data),
              const SizedBox(height: 20),
              _buildTrendChart(data),
              const SizedBox(height: 20),
              _buildRegionPieChart(data),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(List<SalesStats> data) {
    double totalSales = data.fold(0, (sum, item) => sum + item.sAmts);
    double totalProfit = data.fold(0, (sum, item) => sum + item.sProfits);
    return Row(
      children: [
        _kpiItem("總銷售額", totalSales, Colors.blue),
        const SizedBox(width: 12),
        _kpiItem("總利潤", totalProfit, Colors.green),
      ],
    );
  }

  Widget _kpiItem(String title, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text('\$${_currencyFormat.format(value)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 年月選擇彈窗邏輯
  // ---------------------------------------------------------------------------
  Future<String?> _showMonthPicker(BuildContext context, String currentYYMM) async {
    int selectedYear = int.parse(currentYYMM.substring(0, 4));
    int selectedMonth = int.parse(currentYYMM.substring(4, 6));

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setDialogState(() => selectedYear--)),
                Text('$selectedYear 年'),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setDialogState(() => selectedYear++)),
              ],
            ),
            content: SizedBox(
              width: 300,
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2),
                itemCount: 12,
                itemBuilder: (context, index) {
                  int month = index + 1;
                  return InkWell(
                    onTap: () => Navigator.pop(context, '$selectedYear${month.toString().padLeft(2, '0')}'),
                    child: Center(child: Text('$month月', style: TextStyle(color: month == selectedMonth ? Colors.blue : Colors.black))),
                  );
                },
              ),
            ),
          );
        });
      },
    );
  }
}