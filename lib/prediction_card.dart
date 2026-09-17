import 'package:flutter/material.dart';

class PredictionRealityCard extends StatelessWidget {
  const PredictionRealityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
            // Title Row with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology_outlined, color: Colors.deepPurple, size: 26),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Today's AI Analysis",
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
            
            // Information Rows
            _buildDataRow(
              label: "DEAR 1PM Machine", 
              value: "75569", 
              icon: Icons.memory, 
              iconColor: Colors.grey.shade500, 
              valueColor: Colors.black87
            ),
            const SizedBox(height: 16),
            _buildDataRow(
              label: "AI Predicted Result", 
              value: "45298", 
              icon: Icons.batch_prediction_outlined, 
              iconColor: Colors.blue.shade400, 
              valueColor: Colors.blue.shade700
            ),
            const SizedBox(height: 16),
            _buildDataRow(
              label: "Actual Result", 
              value: "76988", 
              icon: Icons.check_circle_outline, 
              iconColor: Colors.green.shade400, 
              valueColor: Colors.green.shade700
            ),
            
            const SizedBox(height: 20),
            const Divider(height: 1, thickness: 1),
            const SizedBox(height: 20),
            
            // Highlighted Difference Row
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
                      Icon(Icons.difference_outlined, color: Colors.red.shade400, size: 22),
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
                    "31,690",
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

  // Helper method for clean row layout
  Widget _buildDataRow({
    required String label, 
    required String value, 
    required IconData icon, 
    required Color iconColor, 
    required Color valueColor
  }) {
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
