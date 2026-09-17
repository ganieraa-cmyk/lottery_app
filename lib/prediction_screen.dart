import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionScreen extends StatelessWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Live AI Analysis',
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
        child: StreamBuilder<DocumentSnapshot>(
          // Listening real-time to Document '16' in 'september_2026_draws'
          stream: FirebaseFirestore.instance.collection('september_2026_draws').doc('16').snapshots(),
          builder: (context, snapshot) {
            // Loading State
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
            }
            
            // Error State
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error loading data: \n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }
            
            // Document Not Found State
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  "Data not found! Make sure Document '16' exists.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            // Extract Data Safely
            final data = snapshot.data!.data() as Map<String, dynamic>;
            
            // Note: Your initial upload might have saved it as 'DEAR 1PM MC' instead of 'DEAR 1PM Machine'
            final machine = data['DEAR 1PM MC'] ?? data['DEAR 1PM Machine'] ?? 'N/A';
            final prediction = data['AI_Prediction'] ?? 'N/A';
            final result = data['DEAR 1PM Result'] ?? 'N/A';
            final errorMargin = data['AI_Error_Margin'] ?? 'N/A';

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDashboardCard(
                    machine: machine.toString(),
                    prediction: prediction.toString(),
                    result: result.toString(),
                    errorMargin: errorMargin.toString(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String machine,
    required String prediction,
    required String result,
    required String errorMargin,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cloud_sync, color: Colors.deepPurple, size: 26),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Firebase Live Data",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 20),
            
            _buildDataRow("DEAR 1PM Machine", machine, Icons.memory, Colors.grey.shade500, Colors.black87),
            const SizedBox(height: 16),
            _buildDataRow("AI Predicted Result", prediction, Icons.batch_prediction, Colors.blue.shade400, Colors.blue.shade700),
            const SizedBox(height: 16),
            _buildDataRow("Actual Result", result, Icons.check_circle, Colors.green.shade400, Colors.green.shade700),
            
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.difference, color: Colors.red.shade400, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        "AI Difference",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    errorMargin,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.red.shade700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value, IconData icon, Color iconColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
