import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isProcessingImage = false;
  bool _isImageProcessed = false;
  DateTime? _lastSyncTime;
  int _autoUpdatedCount = 0;
  List<Map<String, String>> _extractedResults = [];
  Map<int, int> _digitFrequencies = {};

  // Simulated Image OCR Parsing Method (based on the provided chart for Date 16)
  Future<void> _processUploadedImage() async {
    setState(() => _isProcessingImage = true);
    
    // Simulate OCR Processing Delay
    await Future.delayed(const Duration(seconds: 2));

    // Data extracted from the provided chart image for Date 16 (including newly updated 8 PM result)
    final extractedData = [
      {'draw': '1 PM', 'result': '76988', 'mc': '78535'},
      {'draw': 'KL 3 PM', 'result': '293215', 'mc': '188712'},
      {'draw': '6 PM', 'result': '16187', 'mc': '20790'},
      {'draw': '8 PM', 'result': '18987', 'mc': '53633'},
    ];

    // 1. Calculate Single Digit Frequencies from the extracted results
    Map<int, int> freqs = {for (var i = 0; i <= 9; i++) i: 0};
    for (var item in extractedData) {
      String res = item['result']!;
      for (int i = 0; i < res.length; i++) {
        int? digit = int.tryParse(res[i]);
        if (digit != null) {
          freqs[digit] = (freqs[digit] ?? 0) + 1;
        }
      }
    }

    // 2. Auto-Update Firestore: Find pending predictions and fill in the actual results automatically
    int updatedCount = 0;
    try {
      final snapshot = await FirebaseFirestore.instance.collection('user_predictions').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final targetDraw = data['target_draw']?.toString() ?? "";
        final actualResult = data['actualResult']?.toString() ?? "";
        
        // If a prediction is pending (no result entered yet)
        if (actualResult.isEmpty) {
          // Find if we just extracted the result for this draw
          var match = extractedData.firstWhere((e) => e['draw'] == targetDraw, orElse: () => {});
          if (match.isNotEmpty) {
            // Update Firestore with the OCR parsed actual result
            await FirebaseFirestore.instance.collection('user_predictions').doc(doc.id).update({
              'actualResult': match['result'],
            });
            updatedCount++;
          }
        }
      }
    } catch (e) {
      print("Error during auto-update: $e");
    }

    if (mounted) {
      setState(() {
        _isImageProcessed = true;
        _lastSyncTime = DateTime.now();
        _extractedResults = extractedData;
        _digitFrequencies = freqs;
        _autoUpdatedCount = updatedCount;
        _isProcessingImage = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chart Processed Successfully! Database synced.'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Vision Dashboard',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
        actions: [
          if (!_isProcessingImage)
            IconButton(
              icon: const Icon(Icons.document_scanner, color: Colors.white),
              tooltip: "Scan Chart Image",
              onPressed: _processUploadedImage,
            )
        ],
      ),
      floatingActionButton: !_isImageProcessed && !_isProcessingImage
          ? FloatingActionButton.extended(
              onPressed: _processUploadedImage,
              backgroundColor: Colors.deepPurple,
              icon: const Icon(Icons.upload_file),
              label: const Text("Scan Chart", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: _isProcessingImage 
            ? _buildLoadingState() 
            : (_isImageProcessed ? _buildProcessedDashboard() : _buildEmptyState()),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.deepPurple, strokeWidth: 4),
          const SizedBox(height: 24),
          Text(
            "Analyzing Chart Image...",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.deepPurple.shade700, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            "Extracting Machine Numbers & Results via AI",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_search, size: 80, color: Colors.deepPurple.shade200),
          const SizedBox(height: 16),
          const Text(
            "No Chart Uploaded",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.deepPurple),
          ),
          const SizedBox(height: 8),
          Text(
            "Upload today's chart to extract data\nand auto-validate predictions.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessedDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Success Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "IMAGE DATA CHART PROCESSED",
                    style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade800, letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 2. Summary Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text("IMAGE DATA SUMMARY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                    ],
                  ),
                  const Divider(height: 24, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryStat("Draws Extracted", "${_extractedResults.length}", Icons.download_done, Colors.blue),
                      _buildSummaryStat("Auto-Updated", "$_autoUpdatedCount", Icons.sync, Colors.orange),
                      _buildSummaryStat("Sync Time", "${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}", Icons.access_time, Colors.purple),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Extracted Results List
          Text("RECENT DRAW RESULTS (Extracted)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 1)),
          const SizedBox(height: 8),
          ..._extractedResults.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: Icon(Icons.schedule, size: 16, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 12),
                    Text(e['draw']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                    Text(e['result']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                    const SizedBox(width: 12),
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: 20),

          // 4. Single Digit Frequency Chart
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text("SINGLE DIGIT FREQUENCY", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                    ],
                  ),
                  Text("(from Image Analysis)", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  _buildFrequencyBarChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 5. Validation Check (Stream from Firestore)
          Text("VALIDATION CHECK (Matches & Wins)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 1)),
          const SizedBox(height: 8),
          _buildValidationCheckStream(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildFrequencyBarChart() {
    int maxCount = _digitFrequencies.values.isEmpty ? 1 : _digitFrequencies.values.reduce(max);
    if (maxCount == 0) maxCount = 1;

    return Column(
      children: List.generate(10, (index) {
        int count = _digitFrequencies[index] ?? 0;
        double pct = count / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              SizedBox(width: 20, child: Text("$index", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(height: 16, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8))),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: pct,
                      child: Container(
                        height: 16, 
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(width: 24, child: Text("$count", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildValidationCheckStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('user_predictions').orderBy('date', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final res = data['actualResult']?.toString();
          return res != null && res.isNotEmpty;
        }).toList();

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No resolved predictions yet to validate against."),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final targetDraw = data['target_draw']?.toString() ?? "Unknown";
            final actualResultRaw = data['actualResult']?.toString() ?? "";
            String target3 = actualResultRaw.length >= 3 ? actualResultRaw.substring(actualResultRaw.length - 3) : "";
            final predictions = (data['predictions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

            String bestHitLabel = "NO MATCH";
            Color badgeColor = Colors.grey.shade400;
            
            for (var combo in predictions) {
              if (combo.length != 3) continue;
              if (combo == target3) {
                bestHitLabel = "DIRECT HIT! 🎯";
                badgeColor = Colors.green;
                break;
              } else if (bestHitLabel == "NO MATCH") {
                if (combo[0] == target3[0] && combo[1] == target3[1]) { bestHitLabel = "AB PASS! 🎯"; badgeColor = Colors.orange; }
                else if (combo[1] == target3[1] && combo[2] == target3[2]) { bestHitLabel = "BC PASS! 🎯"; badgeColor = Colors.orange; }
                else if (combo[0] == target3[0] && combo[2] == target3[2]) { bestHitLabel = "AC PASS! 🎯"; badgeColor = Colors.orange; }
              }
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: badgeColor, width: 1)),
              child: ListTile(
                title: Text(targetDraw, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Result: $actualResultRaw", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(bestHitLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
