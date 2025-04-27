import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' as io;

class PastProjectsScreen extends StatelessWidget {
  const PastProjectsScreen({super.key});

  Future<void> downloadFile(BuildContext context, String fileUrl, String fileName) async {
    try {
      if (kIsWeb) {
        // Web download
        final anchor = html.AnchorElement(href: fileUrl)
          ..setAttribute('download', fileName)
          ..click();
      } else {
        // Request permission for Android
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Storage permission denied")),
          );
          return;
        }

        // Download the file using Dio
        final tempDir = io.Directory.systemTemp;
        final tempFilePath = '${tempDir.path}/$fileName';

        await Dio().download(fileUrl, tempFilePath);

        // Save to Downloads directory using MediaStore
        final mediaStore = MediaStore();
        final saveInfo = await mediaStore.saveFile(
          tempFilePath: tempFilePath,
          dirType: DirType.download,
          dirName: DirName.download,
        );

        if (saveInfo != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("File downloaded to Downloads: $saveInfo")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save file to Downloads")),
          );
        }
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error downloading file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('blueprints')
      .orderBy('uploadedAt', descending: true)
      .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("An error occurred while loading data."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("No past blueprints uploaded yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final blueprintData = docs[index].data() as Map<String, dynamic>;

            final fileName = blueprintData['fileName'] ?? 'Unnamed File';
            final fileUrl = blueprintData['fileUrl'];
            final description = blueprintData['description'] ?? '';
            final uploadedAt = blueprintData['uploadedAt'] != null
                ? (blueprintData['uploadedAt'] as Timestamp).toDate()
                : null;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.insert_drive_file, size: 35, color: Colors.blue),
                title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    if (uploadedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          "Uploaded: ${uploadedAt.toLocal()}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
                trailing: fileUrl != null
                    ? IconButton(
                        icon: const Icon(Icons.download_rounded, color: Colors.green),
                        onPressed: () => downloadFile(context, fileUrl, fileName),
                      )
                    : const Icon(Icons.block, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }
}
