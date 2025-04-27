import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final ordersRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('orders'); // 👈 orders under user collection

    return Scaffold(
      appBar: AppBar(title: const Text("Placed Orders")),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersRef.orderBy('time', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allOrders = snapshot.data!.docs;
          final pendingOrders = allOrders.where((doc) => doc['status'] == 'Pending').toList();
          final deliveredOrders = allOrders.where((doc) => doc['status'] == 'Delivered').toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Pending Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ...pendingOrders.map((order) {
                  final name = order['name'];
                  final qty = order['quantity'];
                  final time = (order['time'] as Timestamp).toDate();

                  return ListTile(
                    title: Text("Order: $name"),
                    subtitle: Text("Qty: $qty • Time: ${time.toLocal()}"),
                    trailing: TextButton(
                      onPressed: () async {
                        final materialRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('materials')
                            .doc(name.toLowerCase()); // assuming material document name is lowercase item name

                        final materialSnapshot = await materialRef.get();
                        final currentQty = materialSnapshot['quantity'] ?? 0;

                        // Update material quantity
                        await materialRef.update({
                          'quantity': currentQty + qty,
                        });

                        // Mark the order as delivered
                        await ordersRef.doc(order.id).update({'status': 'Delivered'});
                      },
                      child: const Text("Mark Delivered"),
                    ),
                  );
                }),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text("Past Orders", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ...deliveredOrders.map((order) {
                  final name = order['name'];
                  final qty = order['quantity'];
                  final time = (order['time'] as Timestamp).toDate();

                  return ListTile(
                    title: Text("Order: $name"),
                    subtitle: Text("Qty: $qty • Time: ${time.toLocal()}"),
                    trailing: const Icon(Icons.check, color: Colors.green),
                  );
                }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showOrderDialog(BuildContext context) {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Place a New Order"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: "Quantity"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;

              if (name.isNotEmpty && qty > 0) {
                final uid = FirebaseAuth.instance.currentUser?.uid;
                await FirebaseFirestore.instance.collection('users').doc(uid).collection('orders').add({
                  'name': name,
                  'quantity': qty,
                  'time': Timestamp.now(),
                  'status': 'Pending',
                });

                Navigator.pop(context);
              }
            },
            child: const Text("Place Order"),
          ),
        ],
      ),
    );
  }
}
