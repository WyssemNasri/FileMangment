import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

import 'Constant.dart';

class UploadFileScreen extends StatefulWidget {
  final String folderId;

  const UploadFileScreen({super.key, required this.folderId});

  @override
  _UploadFileScreenState createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  File? _file;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple:
          false, // Change to true if you want to allow multiple files
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf'
      ], // Add other file types if needed
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _file = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uri = Uri.parse('$endpoint/${widget.folderId}/files');
      final request = http.MultipartRequest('POST', uri)
        ..fields['folderId'] = widget.folderId
        ..files.add(await http.MultipartFile.fromPath('file', _file!.path));

      final response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
        Navigator.pop(context); // Close the upload screen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload file: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload File'),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo Section
            Center(
              child: Image.asset(
                'images/logocpg.png', // Update the path if needed
                height: 100,
                width: 100,
              ),
            ),
            const SizedBox(height: 16.0),

            // File Pick Button
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700], // Button color
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text('Pick File'),
            ),
            const SizedBox(height: 16.0),

            // Selected File Display
            if (_file != null) ...[
              Text(
                'Selected File: ${path.basename(_file!.path)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),

              // Upload Button
              ElevatedButton(
                onPressed: _uploadFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700], // Button color
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Upload File'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
