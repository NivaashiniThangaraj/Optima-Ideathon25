import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThresholdEditorPage extends StatefulWidget {
  const ThresholdEditorPage({super.key});

  @override
  State<ThresholdEditorPage> createState() => _ThresholdEditorPageState();
}

class _ThresholdEditorPageState extends State<ThresholdEditorPage> {
  final firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _isSaving = {}; // Track saving state per material

  // Get the current user's ID
  String? get userId => _auth.currentUser?.uid;

  @override
  void dispose() {
    // Dispose all controllers to prevent memory leaks
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if the user is logged in
    if (userId == null) {
      return const Center(child: Text("Please log in to access this page"));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Set Threshold Limits")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('users')
            .doc(userId) // Access user-specific data
            .collection('materials')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final materials = snapshot.data!.docs;

          if (materials.isEmpty) {
            return const Center(child: Text("No materials found."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: materials.length,
            itemBuilder: (context, index) {
              final material = materials[index];
              final name = material['name'];
              final quantity = material['quantity'];
              final threshold = material['threshold'] ?? 0;
              final docId = material.id;

              _controllers.putIfAbsent(
                docId,
                () => TextEditingController(text: threshold.toString()),
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text("$name (Stock: $quantity)"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controllers[docId],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Set Threshold",
                          hintText: "Enter a non-negative number",
                        ),
                        onChanged: (value) {
                          // Optional: Immediate feedback while typing can be handled here
                        },
                        onSubmitted: (value) async {
                          final newThreshold = int.tryParse(value);
                          if (newThreshold == null || newThreshold < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please enter a valid number")),
                            );
                            _controllers[docId]!.text = threshold.toString();
                            return;
                          }

                          setState(() {
                            _isSaving[docId] = true; // Set saving state
                          });

                          try {
                            await firestore
                                .collection('users')
                                .doc(userId) // Access user-specific data
                                .collection('materials')
                                .doc(docId)
                                .update({
                              'threshold': newThreshold,
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Threshold updated")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          } finally {
                            setState(() {
                              _isSaving[docId] = false; // Reset saving state
                            });
                          }
                        },
                      ),
                      if (_isSaving[docId] == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
