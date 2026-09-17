import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<QuerySnapshot>? _predictionsFuture;
  
  // Track text controllers for each document ID to prevent memory leaks and sharing state
  final Map<String, TextEditingController> _resultControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPredictions();
  }

  void _loadPredictions() {
    setState(() {
      _predictionsFuture = FirebaseFirestore.instance
          .collection('user_predictions')
          .orderBy('date', descending: true)
          .get();
    });
  }

  Future<void> _handleRefresh() async {
    _loadPredictions();
    await _predictionsFuture;
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown Date";
    DateTime dt = timestamp.toDate();
    String day = dt.day.toString().padLeft(2, '0');
    String month = dt.month.toString().padLeft(2, '0');
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String min = dt.minute.toString().padLeft(2, '0');
    String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$day/$month/${dt.year}  $hour:$min $ampm";
  }
  
  Future<void> _updateActualResult(String docId, String actualResult, int reqLength) async {
    if (actualResult.length != reqLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Result must be exactly $reqLength digits for this draw!'), backgroundColor: Colors.red),
      );
      return;
    }
    
    try {
      await FirebaseFirestore.instance.collection('user_predictions').doc(docId).update({
        'actualResult': actualResult,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Actual result updated!'), backgroundColor: Colors.green),
        );
        _handleRefresh(); // Reload to show the updated hit status
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _resultControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Prediction History',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
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
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: Colors.deepPurple,
          child: FutureBuilder<QuerySnapshot>(
            future: _predictionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error loading history:\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return ListView(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    const Center(
                      child: Text(
                        "No saved predictions found.\nGo to the Predict tab to save one!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ],
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return _buildHistoryCard(doc);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;
    
    final timestamp = data['date'] as Timestamp?;
    final targetDraw = data['target_draw']?.toString() ?? "Unknown Draw";
    final inputs = data['inputs'] as Map<String, dynamic>? ?? {};
    final predictions = (data['predictions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    
    bool isKL = targetDraw.contains('KL');
    int reqLength = isKL ? 6 : 5;

    // Check for actual result
    final actualResultRaw = data['actualResult']?.toString();
    final bool hasResult = actualResultRaw != null && actualResultRaw.isNotEmpty && actualResultRaw.length >= 3;
    
    String target3 = "";
    if (hasResult) {
      // Extract the last 3 digits dynamically regardless of 5 or 6 digit input length
      target3 = actualResultRaw.substring(actualResultRaw.length - 3);
    }

    // Advanced Validation Matcher
    String? getMatchStatus(String combo) {
      if (!hasResult || combo.length != 3 || target3.length != 3) return null;
      if (combo == target3) return "Direct Hit!";
      if (combo[0] == target3[0] && combo[1] == target3[1]) return "AB Pass!";
      if (combo[1] == target3[1] && combo[2] == target3[2]) return "BC Pass!";
      if (combo[0] == target3[0] && combo[2] == target3[2]) return "AC Pass!";
      return null;
    }

    String bestCardHit = "";
    if (hasResult) {
      for (var combo in predictions) {
        String? status = getMatchStatus(combo);
        if (status == "Direct Hit!") {
          bestCardHit = "DIRECT HIT! 🎯";
          break; 
        } else if (status != null && bestCardHit == "") {
          bestCardHit = "PARTIAL HIT! 🎯";
        }
      }
    }

    final bool isDirectHit = bestCardHit.contains("DIRECT");
    final bool isHit = bestCardHit.isNotEmpty;
    
    Color hitColor = isDirectHit ? Colors.green : (isHit ? Colors.orange.shade600 : Colors.transparent);
    Color hitLightColor = isDirectHit ? Colors.green.shade50 : (isHit ? Colors.orange.shade50 : Colors.transparent);
    Color hitBorderColor = isDirectHit ? Colors.green.shade200 : (isHit ? Colors.orange.shade300 : Colors.transparent);

    // Initialize controller for this specific card
    _resultControllers.putIfAbsent(docId, () => TextEditingController(text: actualResultRaw));

    return Card(
      elevation: isHit ? 12 : 6,
      shadowColor: isHit ? hitColor.withOpacity(0.4) : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isHit ? BorderSide(color: hitColor, width: 2) : BorderSide.none,
      ),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border(
            left: BorderSide(color: isHit ? hitColor : Colors.deepPurple.shade400, width: 8),
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(isHit ? Icons.workspace_premium : Icons.stars, color: isHit ? hitColor : Colors.amber.shade600, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      targetDraw,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isHit ? (isDirectHit ? Colors.green.shade800 : Colors.orange.shade900) : Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatDateTime(timestamp),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(height: 1, thickness: 1),
            ),
            
            // Input Parameters Section
            Text(
              "INPUT PARAMETERS",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: inputs.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          e.value.toString(),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Generated Combinations Chip Grid
            Text(
              "GENERATED 3-DIGIT COMBINATIONS",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: predictions.map((combo) {
                String? matchStatus = getMatchStatus(combo);
                bool isWinningCombo = matchStatus != null;
                bool isDirect = matchStatus == "Direct Hit!";
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isWinningCombo 
                        ? (isDirect ? Colors.green : Colors.orange.shade500) 
                        : Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isWinningCombo 
                            ? (isDirect ? Colors.green.shade700 : Colors.orange.shade700) 
                            : Colors.deepPurple.shade200, 
                        width: isWinningCombo ? 2 : 1),
                    boxShadow: isWinningCombo 
                        ? [BoxShadow(
                             color: (isDirect ? Colors.green : Colors.orange).withOpacity(0.4), 
                             blurRadius: 8, 
                             offset: const Offset(0, 3)
                           )] 
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            combo,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isWinningCombo ? Colors.white : Colors.deepPurple,
                              letterSpacing: 4,
                            ),
                          ),
                          if (isWinningCombo) ...[
                            const SizedBox(width: 8),
                            Icon(isDirect ? Icons.my_location : Icons.check_circle_outline, color: Colors.white, size: 18),
                          ]
                        ],
                      ),
                      if (isWinningCombo)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            matchStatus.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Actual Result Updater Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isHit ? hitLightColor : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isHit ? hitBorderColor : Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isHit ? Icons.emoji_events : Icons.query_stats, color: isHit ? hitColor : Colors.amber.shade800, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isHit ? bestCardHit : (hasResult ? "PREDICTION MISSED" : "ENTER ACTUAL FULL RESULT"),
                        style: TextStyle(
                          fontSize: 13, 
                          fontWeight: FontWeight.w900, 
                          color: isHit ? (isDirectHit ? Colors.green.shade800 : Colors.orange.shade900) : (hasResult ? Colors.grey.shade700 : Colors.amber.shade900),
                          letterSpacing: 1.2
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _resultControllers[docId],
                          keyboardType: TextInputType.number,
                          maxLength: reqLength,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 8, 
                            color: isHit ? (isDirectHit ? Colors.green.shade800 : Colors.orange.shade900) : Colors.black87
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: isKL ? "000000" : "00000",
                            hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 8),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Unfocus keyboard
                          FocusScope.of(context).unfocus();
                          _updateActualResult(docId, _resultControllers[docId]!.text, reqLength);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isHit ? hitColor : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
