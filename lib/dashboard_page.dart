import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for Firebase Authentication

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchInventoryData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }

    // Fetch materials data specific to the authenticated user
    final cementDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('materials')
        .doc('cement')
        .get();
    final bricksDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('materials')
        .doc('bricks')
        .get();
    final steelDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('materials')
        .doc('steel rods')
        .get();

    return [
      {
        'name': cementDoc.data()?['name'] ?? 'Cement',
        'quantity': cementDoc.data()?['quantity'] ?? 0,
        'unit': cementDoc.data()?['unit'] ?? ''
      },
      {
        'name': bricksDoc.data()?['name'] ?? 'Bricks',
        'quantity': bricksDoc.data()?['quantity'] ?? 0,
        'unit': bricksDoc.data()?['unit'] ?? ''
      },
      {
        'name': steelDoc.data()?['name'] ?? 'Steel rods',
        'quantity': steelDoc.data()?['quantity'] ?? 0,
        'unit': steelDoc.data()?['unit'] ?? ''
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Dashboard')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchInventoryData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Error fetching data'));
          }

          final inventory = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text("Inventory Overview", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _buildBarChart(inventory),
                const SizedBox(height: 40),
                _buildPieChart(inventory),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    double maxY = _getMaxYRounded(data); // Round up to nearest 400

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          gridData: FlGridData(show: true),
          barGroups: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: (item['quantity'] as num).toDouble(),
                  color: _getColor(item['name']),
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
              showingTooltipIndicators: [0],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  int index = value.toInt();
                  return index < data.length
                      ? Text(data[index]['name'], style: const TextStyle(fontSize: 12))
                      : const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 400, // Show steps of 400
                getTitlesWidget: (value, _) => Text('${value.toInt()}'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to round up to the nearest 400
  double _getMaxYRounded(List<Map<String, dynamic>> data) {
    double max = data.map((e) => (e['quantity'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    return ((max / 400).ceil() * 400).toDouble();
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: data.map((item) {
            return PieChartSectionData(
              value: (item['quantity'] as num).toDouble(),
              title: '${item['name']}',
              color: _getColor(item['name']),
              radius: 100,
              titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Color _getColor(String name) {
    switch (name.toLowerCase()) {
      case 'cement':
        return Colors.orange;
      case 'bricks':
        return Colors.red;
      case 'steel rods':
        return const Color.fromARGB(255, 201, 201, 48);
      default:
        return Colors.grey;
    }
  }
}
