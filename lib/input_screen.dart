import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedDraw = '1 PM';
  
  // Dynamic Input Controllers
  final _input1 = TextEditingController();
  final _input2 = TextEditingController();
  final _input3 = TextEditingController();
  final _input4 = TextEditingController();
  final _input5 = TextEditingController();

  bool _isLoading = false;
  bool _isFetchingPastData = false;
  
  // Cache of today's previously saved inputs
  Map<String, String> _autoFetchedData = {};

  @override
  void initState() {
    super.initState();
    _fetchTodayPastData();
  }

  // Fetch saved predictions from Firestore to smartly auto-fill repetitive fields
  Future<void> _fetchTodayPastData() async {
    setState(() {
      _isFetchingPastData = true;
      _autoFetchedData.clear();
    });
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfYesterday = startOfDay.subtract(const Duration(days: 1));
      
      // Fetch documents saved from yesterday onwards
      final snapshot = await FirebaseFirestore.instance
          .collection('user_predictions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYesterday))
          .orderBy('date', descending: true)
          .get();

      Map<String, String> foundData = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('date')) continue;
        
        final docDate = (data['date'] as Timestamp).toDate();
        bool isToday = docDate.isAfter(startOfDay) || docDate.isAtSameMomentAs(startOfDay);
        bool isYesterday = docDate.isBefore(startOfDay) && (docDate.isAfter(startOfYesterday) || docDate.isAtSameMomentAs(startOfYesterday));

        // 1. Process previous inputs
        if (data.containsKey('inputs')) {
          final inputs = data['inputs'] as Map<String, dynamic>;
          inputs.forEach((key, value) {
            String mappedKey = key;
            // Shift yesterday's "Today" inputs to "Yesterday" dynamically!
            if (isYesterday && key.startsWith("Today")) {
              mappedKey = key.replaceFirst("Today", "Yesterday"); 
            }
            if (!foundData.containsKey(mappedKey)) {
              foundData[mappedKey] = value.toString();
            }
          });
        }
        
        // 2. Process cross-screen actualResult mappings!
        // This bridges the HistoryScreen actual results directly into the InputScreen fields.
        if (data.containsKey('actualResult') && data.containsKey('target_draw')) {
          String actualResult = data['actualResult'].toString();
          String targetDraw = data['target_draw'].toString(); // e.g., "1 PM"
          if (actualResult.isNotEmpty) {
             String baseLabel = "${targetDraw.replaceAll(' ', '')} Result"; // e.g., "1PM Result"
             String mappedKey = isToday ? "Today $baseLabel" : "Yesterday $baseLabel";
             
             if (!foundData.containsKey(mappedKey)) {
               foundData[mappedKey] = actualResult;
             }
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _autoFetchedData = foundData;
          _isFetchingPastData = false;
          _applyAutoFetchedData();
        });
      }
    } catch (e) {
      print("Auto-fetch error: $e");
      if (mounted) {
        setState(() {
          _isFetchingPastData = false;
        });
      }
    }
  }

  // Applies fetched data to fields 2-5. Field 1 is always manual.
  void _applyAutoFetchedData() {
    List<String> labels = _getLabels();
    
    // Clear primary input as it always requires manual entry for the new draw
    _input1.clear();
    
    // Auto-fill remaining fields if data exists, otherwise clear them for manual fallback
    _autoFetchedData.containsKey(labels[1]) ? _input2.text = _autoFetchedData[labels[1]]! : _input2.clear();
    _autoFetchedData.containsKey(labels[2]) ? _input3.text = _autoFetchedData[labels[2]]! : _input3.clear();
    _autoFetchedData.containsKey(labels[3]) ? _input4.text = _autoFetchedData[labels[3]]! : _input4.clear();
    _autoFetchedData.containsKey(labels[4]) ? _input5.text = _autoFetchedData[labels[4]]! : _input5.clear();
  }

  List<String> _getLabels() {
    if (_selectedDraw == '1 PM') {
      return [
        'Today 1PM MC',
        'Yesterday 6PM MC',
        'Yesterday 6PM Result',
        'Yesterday 8PM MC',
        'Yesterday 8PM Result',
      ];
    } else if (_selectedDraw == '6 PM') {
      return [
        'Today 6PM MC',
        'Today 1PM MC',
        'Today 1PM Result',
        'Today KL 3PM MC',
        'Today KL 3PM Result',
      ];
    } else {
      return [
        'Today 8PM MC',
        'Today 6PM MC',
        'Today 6PM Result',
        'Today KL 3PM Result',
        'Today 1PM Result',
      ];
    }
  }

  void _onPredictPressed() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();

      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1000)); // Faster simulation for lightning UX

      if (!mounted) return;
      setState(() => _isLoading = false);

      List<String> inputs = [_input1.text, _input2.text, _input3.text, _input4.text, _input5.text];
      List<String> labels = _getLabels();
      List<String> digitPool = [];
      List<String> validDoubles = [];

      for (int i = 0; i < inputs.length; i++) {
        String input = inputs[i];
        String label = labels[i];
        
        int reqLength = label.contains('KL') ? 6 : 5;

        if (input.length == reqLength) {
          digitPool.add(input[0]); 
          digitPool.add(input[input.length - 1]); 

          if (input[0] == input[1]) {
            validDoubles.add(input[0] + input[1]);
          }
          if (input[input.length - 2] == input[input.length - 1]) {
            validDoubles.add(input.substring(input.length - 2));
          }
        }
      }

      final random = Random();
      int totalCombos = random.nextInt(4) + 5; 
      Set<String> uniqueCombos = {};
      bool allowsDoubles = validDoubles.isNotEmpty;

      String generatePoolCombo() {
        List<String> poolCopy = List.from(digitPool);
        poolCopy.shuffle(random);
        return poolCopy[0] + poolCopy[1] + poolCopy[2];
      }

      bool hasRepeatingDigits(String s) => s[0] == s[1] || s[1] == s[2] || s[0] == s[2];

      if (allowsDoubles) {
        for (String dbl in validDoubles) {
          String singleDigit = digitPool[random.nextInt(digitPool.length)];
          int pattern = random.nextInt(3);
          String combo;
          if (pattern == 0) {
            combo = dbl + singleDigit;
          } else if (pattern == 1) {
            combo = dbl[0] + singleDigit + dbl[1];
          } else {
            combo = singleDigit + dbl;
          }
          uniqueCombos.add(combo);
        }
      }

      int failsafe = 0;
      int uniqueDigitsInPool = digitPool.toSet().length;

      while (uniqueCombos.length < totalCombos && failsafe < 200) {
        failsafe++;
        String combo = generatePoolCombo();

        if (!allowsDoubles && uniqueDigitsInPool >= 3) {
          if (hasRepeatingDigits(combo)) continue; 
        }
        uniqueCombos.add(combo);
      }

      List<String> finalCombinations = uniqueCombos.toList();
      finalCombinations.shuffle(random);

      _showResultDialog(finalCombinations, inputs, labels);
    }
  }

  void _showResultDialog(List<String> combinations, List<String> inputs, List<String> labels) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.psychology, color: Colors.amber.shade600, size: 28),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Highly Probable Last 3 Digits 🎯", 
                  style: TextStyle(fontWeight: FontWeight.w900, color: Colors.deepPurple, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Based on the 10-digit edge pool from your inputs, here are the most likely 3-digit endings for the next $_selectedDraw draw:",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: combinations.map((combo) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade200, width: 2),
                    ),
                    child: Text(
                      combo,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.deepPurple, letterSpacing: 4),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("DISMISS", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('user_predictions').add({
                    'date': FieldValue.serverTimestamp(),
                    'target_draw': _selectedDraw,
                    'inputs': {
                      labels[0]: inputs[0].toString(),
                      labels[1]: inputs[1].toString(),
                      labels[2]: inputs[2].toString(),
                      labels[3]: inputs[3].toString(),
                      labels[4]: inputs[4].toString(),
                    },
                    'predictions': combinations.toList(),
                  });
                  
                  // Immediately refresh cache so subsequent predictions auto-fill newly saved data
                  _fetchTodayPastData();
                  
                  if (context.mounted) {
                    Navigator.of(context).pop(); 
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Prediction Saved!', style: TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  print('Firebase Save Error: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save prediction: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SAVE TO FIREBASE", style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _input1.dispose();
    _input2.dispose();
    _input3.dispose();
    _input4.dispose();
    _input5.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> currentLabels = _getLabels();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Target 3-Digits Predictor',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Card(
              elevation: 10,
              shadowColor: Colors.deepPurple.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.deepPurple.shade50, shape: BoxShape.circle),
                            child: const Icon(Icons.bolt, size: 32, color: Colors.deepPurple),
                          ),
                          const SizedBox(width: 16),
                          const Text("Smart Predictor", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Dropdown for Draw Time
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.deepPurple.shade200, width: 2),
                          boxShadow: [BoxShadow(color: Colors.deepPurple.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDraw,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.deepPurple),
                            iconSize: 32,
                            isExpanded: true,
                            style: const TextStyle(color: Colors.deepPurple, fontSize: 18, fontWeight: FontWeight.w900),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedDraw = newValue;
                                  _applyAutoFetchedData();
                                });
                              }
                            },
                            items: <String>['1 PM', '6 PM', '8 PM'].map((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text('Target Draw Time: $value'));
                            }).toList(),
                          ),
                        ),
                      ),
                      
                      // Loading indicator for auto-fetch
                      if (_isFetchingPastData)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple)),
                              const SizedBox(width: 12),
                              Text("Auto-fetching previous inputs...", style: TextStyle(color: Colors.deepPurple.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        const SizedBox(height: 24),

                      // Dynamic Input Fields (Field 1 is Primary, the rest can be auto-filled)
                      _buildInputField(currentLabels[0], _input1, isPrimary: true),
                      _buildInputField(currentLabels[1], _input2),
                      _buildInputField(currentLabels[2], _input3),
                      _buildInputField(currentLabels[3], _input4),
                      _buildInputField(currentLabels[4], _input5),
                      
                      const SizedBox(height: 16),
                      
                      // Predict Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onPredictPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text("PREDICT TARGET 3-DIGITS", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Streamlined UI input builder
  Widget _buildInputField(String label, TextEditingController controller, {bool isPrimary = false}) {
    bool isKL = label.contains('KL');
    int reqLength = isKL ? 6 : 5;
    
    // Check if this field was successfully auto-filled from cache
    bool isAutoFilled = !isPrimary && _autoFetchedData.containsKey(label) && controller.text.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        readOnly: isAutoFilled, // Lock the field if it was fetched from Firebase
        keyboardType: TextInputType.number,
        maxLength: reqLength,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.w900, 
          letterSpacing: 8,
          color: isAutoFilled ? Colors.green.shade700 : Colors.deepPurple,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          labelText: label + (isPrimary ? ' (Current Draw)' : ''),
          labelStyle: TextStyle(
            color: isAutoFilled ? Colors.green.shade700 : (isPrimary ? Colors.deepPurple : Colors.grey.shade600), 
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          hintText: isKL ? "000000" : "00000",
          hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 8),
          filled: true,
          fillColor: isAutoFilled ? Colors.green.shade50 : (isPrimary ? Colors.deepPurple.shade50 : Colors.grey.shade50),
          counterText: "", 
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          suffixIcon: isAutoFilled 
              ? const Icon(Icons.cloud_done, color: Colors.green) 
              : (isPrimary ? const Icon(Icons.edit, color: Colors.deepPurple) : null),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isAutoFilled ? Colors.green.shade300 : (isPrimary ? Colors.deepPurple : Colors.grey.shade300), 
              width: isPrimary || isAutoFilled ? 2 : 1
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isAutoFilled ? Colors.green.shade300 : (isPrimary ? Colors.deepPurple.shade200 : Colors.grey.shade300), 
              width: isPrimary || isAutoFilled ? 2 : 1
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isAutoFilled ? Colors.green : Colors.deepPurple, width: 2),
          ),
          errorStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return "Required";
          if (value.length != reqLength) return "Must be exactly $reqLength digits";
          return null;
        },
      ),
    );
  }
}
