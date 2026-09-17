import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'lottery_chart.dart';
import 'prediction_card.dart';
import 'package:excel/excel.dart' hide Border;

class LotteryData {
  final String date;
  final String dear1pmMC;
  final String dear1pmResult;
  final String kl3pmMC;
  final String kl3pmResult;
  final String dear6pmMC;
  final String dear6pmResult;
  final String dear8pmMC;
  final String dear8pmResult;

  LotteryData({
    required this.date,
    required this.dear1pmMC,
    required this.dear1pmResult,
    required this.kl3pmMC,
    required this.kl3pmResult,
    required this.dear6pmMC,
    required this.dear6pmResult,
    required this.dear8pmMC,
    required this.dear8pmResult,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<LotteryData> lotteryResults = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadExcelData();
  }

  Future<void> _loadExcelData() async {
    try {
      ByteData data = await rootBundle.load('assets/lottery_data.xlsx');
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excel = Excel.decodeBytes(bytes);

      String sheetName = 'Analysis Input';
      if (!excel.tables.containsKey(sheetName) && excel.tables.keys.isNotEmpty) {
        sheetName = excel.tables.keys.first;
      }
      
      var sheet = excel.tables[sheetName];
      
      if (sheet != null) {
        List<LotteryData> tempResults = [];

        var headerRow = sheet.row(0);
        int iDate = 0, i1Mc = 1, i1Res = 2, i3Mc = 3, i3Res = 4, i6Mc = 5, i6Res = 6, i8Mc = 13, i8Res = 14;
        
        for (int c = 0; c < headerRow.length; c++) {
          final header = headerRow[c]?.value?.toString().trim() ?? '';
          if (header == 'Date') iDate = c;
          else if (header == 'DEAR 1PM MC') i1Mc = c;
          else if (header == 'DEAR 1PM Result') i1Res = c;
          else if (header == 'KL 3PM MC') i3Mc = c;
          else if (header == 'KL 3PM Result') i3Res = c;
          else if (header == 'DEAR 6PM MC') i6Mc = c;
          else if (header == 'DEAR 6PM Result') i6Res = c;
          else if (header == 'DEAR 8PM MC') i8Mc = c;
          else if (header == 'DEAR 8PM Result') i8Res = c;
        }

        String safeGet(List<Data?> row, int index) {
          if (index < 0 || index >= row.length) return 'N/A';
          final val = row[index]?.value?.toString() ?? 'N/A';
          if (val.endsWith('.0') && val != 'N/A') return val.replaceAll('.0', '');
          return val;
        }

        for (int i = 1; i < sheet.maxRows; i++) {
          var row = sheet.row(i);
          if (row.isEmpty) continue;

          tempResults.add(LotteryData(
            date: safeGet(row, iDate),
            dear1pmMC: safeGet(row, i1Mc),
            dear1pmResult: safeGet(row, i1Res),
            kl3pmMC: safeGet(row, i3Mc),
            kl3pmResult: safeGet(row, i3Res),
            dear6pmMC: safeGet(row, i6Mc),
            dear6pmResult: safeGet(row, i6Res),
            dear8pmMC: safeGet(row, i8Mc),
            dear8pmResult: safeGet(row, i8Res),
          ));
        }

        setState(() {
          lotteryResults = tempResults;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'No sheets found in the Excel file.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading Excel file.\nDetails: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Excel Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (errorMessage.isNotEmpty) return Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red)));
    if (lotteryResults.isEmpty) return const Center(child: Text("No data found."));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 20, left: 12, right: 12, bottom: 20),
      itemCount: lotteryResults.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 16.0, left: 4, right: 4),
            child: PredictionRealityCard(),
          );
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0, left: 4, right: 4),
            child: LotterySpreadChart(data: lotteryResults),
          );
        }
        final data = lotteryResults[index - 2];
        return _buildFullLotteryCard(data, index - 2);
      },
    );
  }

  Widget _buildFullLotteryCard(LotteryData data, int index) {
    final List<Color> cardColors = [
      const Color(0xFFFFF3E0), const Color(0xFFE3F2FD), const Color(0xFFE8F5E9),
      const Color(0xFFFCE4EC), const Color(0xFFF3E5F5),
    ];
    final cardColor = cardColors[index % cardColors.length];
    
    final List<Color> accentColors = [
      Colors.orange.shade700, Colors.blue.shade700, Colors.green.shade700,
      Colors.pink.shade700, Colors.purple.shade700,
    ];
    final accentColor = accentColors[index % accentColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accentColor, width: 6)),
          ),
          child: Column(
            children: [
              Container(
                color: cardColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month, color: accentColor),
                    const SizedBox(width: 8),
                    Text(
                      "DATE: ${data.date}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildDrawSection("DEAR 1PM", data.dear1pmMC, data.dear1pmResult, Colors.orange.shade600)),
                        Container(width: 1, height: 60, color: Colors.grey.shade200),
                        Expanded(child: _buildDrawSection("KL 3PM", data.kl3pmMC, data.kl3pmResult, Colors.green.shade600)),
                      ],
                    ),
                    const Divider(height: 24, thickness: 1),
                    Row(
                      children: [
                        Expanded(child: _buildDrawSection("DEAR 6PM", data.dear6pmMC, data.dear6pmResult, Colors.blue.shade600)),
                        Container(width: 1, height: 60, color: Colors.grey.shade200),
                        Expanded(child: _buildDrawSection("DEAR 8PM", data.dear8pmMC, data.dear8pmResult, Colors.purple.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawSection(String title, String mc, String result, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: themeColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text("MC", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  Text(mc, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                ],
              ),
              Column(
                children: [
                  Text("RES", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  Text(result, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: themeColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
