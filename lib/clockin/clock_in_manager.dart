import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import './clock_in_model.dart';
import './clock_in_api.dart';
import 'package:intl/intl.dart';

class ClockInManager extends StatefulWidget {
  final String userId;
  const ClockInManager({required this.userId, super.key});

  @override
  State<ClockInManager> createState() => _ClockInManagerState();
}

class _ClockInManagerState extends State<ClockInManager> {
  final ClockInApiService _apiService = ClockInApiService();
  late Future<List<ClockInRecord>> _historyFuture;

  List<ClockInStore> _stores = [];
  ClockInStore? _selectedStore;
  bool _isLoadingStores = true;

  Position? _currentPosition;
  double _distanceInMeters = -1;
  String _currentTime = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initAllData();
    _startClock();
  }

  Future<void> _initAllData() async {
    // 1. 先抓店點
    try {
      final stores = await _apiService.fetchStores();
      if (mounted) {
        setState(() {
          _stores = stores;
          if (_stores.isNotEmpty) _selectedStore = _stores.first;
          _isLoadingStores = false;
        });
        // 2. 抓歷史紀錄
        _refreshHistory();
        // 3. 初次定位
        _handleLocationPermission();
        _updateLocation();
      }
    } catch (e) {
      _showMsg("讀取店點資訊失敗");
    }
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateFormat('HH:mm:ss').format(DateTime.now()));
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 檢查定位服務是否開啟
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMsg('手機定位服務已關閉，請開啟。');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMsg('定位權限被拒絕。');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMsg('定位權限被永久拒絕，請至系統設定開啟。');
      return false;
    }
    return true;
  }

  Future<void> _updateLocation() async {
    if (_selectedStore == null) return;
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double distance = Geolocator.distanceBetween(
          position.latitude, position.longitude,
          _selectedStore!.latitude, _selectedStore!.longitude
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _distanceInMeters = distance;
        });
      }
    } catch (e) {
      print("定位失敗: $e");
    }
  }

  void _refreshHistory() {
    setState(() {
      _historyFuture = _apiService.fetchHistory(widget.userId);
    });
  }

  Future<void> _handleClockIn(String type) async {
    if (_selectedStore == null) return;

    // 再次確認位置
    await _updateLocation();

    if (_distanceInMeters > _selectedStore!.distance) {
      _showMsg("打卡失敗：距離 ${_selectedStore!.storeName} 過遠 (${_distanceInMeters.toInt()}m)");
      return;
    }

    final record = ClockInRecord(
      userId: widget.userId,
      type: type,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
      storeId: _selectedStore!.storeId,
    );

    await _apiService.postClockIn(record);
    /*
    final success = await _apiService.postClockIn(record);
    if (success) {
      _showMsg("$type 打卡成功");
      _refreshHistory();
    }
    */
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isWithinRange = _selectedStore != null &&
        _distanceInMeters >= 0 &&
        _distanceInMeters <= _selectedStore!.distance;

    return Scaffold(
      appBar: AppBar(title: const Text('行動打卡系統')),
      body: _isLoadingStores
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 店點切換
          _buildStorePicker(),
          // 打卡狀態區
          _buildStatusCard(isWithinRange),
          // 歷史紀錄清單
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text("今日紀錄", style: TextStyle(fontWeight: FontWeight.bold))),
          ),
          Expanded(
            child: FutureBuilder<List<ClockInRecord>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final list = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => _buildHistoryTile(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorePicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: DropdownButtonFormField<ClockInStore>(
        initialValue: _selectedStore,
        decoration: const InputDecoration(labelText: "目前打卡店點", border: OutlineInputBorder()),
        items: _stores.map((s) => DropdownMenuItem(value: s, child: Text(s.storeName))).toList(),
        onChanged: (val) {
          setState(() => _selectedStore = val);
          _updateLocation();
        },
      ),
    );
  }

  Widget _buildStatusCard(bool isWithinRange) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.blue.shade50,
      child: Column(
        children: [
          Text(_currentTime, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, color: isWithinRange ? Colors.green : Colors.red),
              Text(
                isWithinRange ? "進入打卡範圍" : "超出範圍 (${_distanceInMeters.toInt()}m / ${_selectedStore?.distance}m)",
                style: TextStyle(color: isWithinRange ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => _handleClockIn("上班"), child: const Text("上班"))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => _handleClockIn("下班"), child: const Text("下班"))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHistoryTile(ClockInRecord record) {
    return ListTile(
      leading: Icon(Icons.access_time, color: record.typeColor),
      title: Text("${record.type} - ${record.formattedDateTime}"),
      subtitle: Text(record.StoreName ?? ""),
    );
  }
}