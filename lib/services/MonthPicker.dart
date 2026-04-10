import 'package:flutter/material.dart';

// 在 channel_sales_manager.dart 檔案下方或獨立檔案
Future<String?> showMonthPicker(BuildContext context, String currentYYMM) async {
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
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setDialogState(() => selectedYear--),
              ),
              Text('$selectedYear 年'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setDialogState(() => selectedYear++),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                int month = index + 1;
                bool isSelected = month == selectedMonth;
                return InkWell(
                  onTap: () {
                    String result = '$selectedYear${month.toString().padLeft(2, '0')}';
                    Navigator.pop(context, result);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$month月',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      });
    },
  );
}