import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadBlueprintScreen extends StatefulWidget {
  const UploadBlueprintScreen({super.key});

  @override
  State<UploadBlueprintScreen> createState() => _UploadBlueprintScreenState();
}

class _UploadBlueprintScreenState extends State<UploadBlueprintScreen> {
  PlatformFile? _selectedFile;
  String _description = "";
  Map<String, dynamic>? _predictedMaterials;

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _selectedFile = result.files.first;
      });
      print("File selected: ${_selectedFile!.name}");
    } else {
      print("File picking cancelled");
    }
  }

  Future<void> _uploadBlueprint() async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to upload.')),
      );
      return;
    }

    if (_selectedFile != null && _description.isNotEmpty) {
      Uint8List? fileBytes = _selectedFile!.bytes;
      String fileName = _selectedFile!.name;

      try {
        Reference storageReference = _storage.ref().child("blueprints/${user.uid}/$fileName");
        await storageReference.putData(fileBytes!);
        String fileUrl = await storageReference.getDownloadURL();

        await _firestore.collection('users').doc(user.uid).collection('blueprints').add({
          'fileName': fileName,
          'fileUrl': fileUrl,
          'description': _description,
          'uploadedAt': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });

        final predictionResult = await _getPredictionFromServer(fileBytes, fileName);
        if (predictionResult != null) {
          setState(() {
            _predictedMaterials = predictionResult;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blueprint uploaded and analyzed!')),
        );
      } catch (e) {
        print('Error uploading blueprint: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error uploading blueprint.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file and enter description')),
      );
    }
  }

  Future<Map<String, dynamic>?> _getPredictionFromServer(Uint8List fileBytes, String fileName) async {
    try {
      var uri = Uri.parse('http://192.168.235.214:5000/predict'); // Use your actual local IP
      var request = http.MultipartRequest('POST', uri)
        ..files.add(http.MultipartFile.fromBytes('image', fileBytes, filename: fileName));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseString = await response.stream.bytesToString();
        return json.decode(responseString);
      } else {
        print("Server error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Prediction error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select Blueprint File'),
              onPressed: _pickFile,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedFile != null ? _selectedFile!.name : 'No file selected',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Description',
              ),
              maxLines: 3,
              onChanged: (value) => _description = value,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadBlueprint,
              child: const Text("Upload Blueprint"),
            ),
            const SizedBox(height: 30),
            if (_predictedMaterials != null) ...[
              const Text(
                "Predicted Materials",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._predictedMaterials!.entries.map((entry) => Text(
                "${entry.key}: ${entry.value.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16),
              )),
            ],
          ],
        ),
      ),
    );
  }
}
