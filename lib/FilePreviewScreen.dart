import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import 'Constant.dart';

class FilePreviewScreen extends StatefulWidget {
  final String fileId;
  final String fileName;

  const FilePreviewScreen({
    super.key,
    required this.fileId,
    required this.fileName,
  });

  @override
  _FilePreviewScreenState createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  bool _isImage = false;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _fetchFile();
  }

  Future<void> _fetchFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse('$endpoint/files/${widget.fileId}');
      print('Fetching file from: $uri');
      final response = await http.get(uri);

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/${widget.fileName}';
        final file = File(filePath);

        await file.writeAsBytes(response.bodyBytes);
        print('File saved to: $filePath');

        setState(() {
          _localFilePath = filePath;
          _isImage = widget.fileName.toLowerCase().endsWith('.jpg') ||
              widget.fileName.toLowerCase().endsWith('.jpeg') ||
              widget.fileName.toLowerCase().endsWith('.png');

          if (_isImage) {
            _pdfController = null;
            print('File is an image.');
          } else {
            try {
              _pdfController = PdfController(
                document: PdfDocument.openFile(filePath),
              );
              print('PDF controller initialized.');
            } catch (e) {
              print('Error initializing PDF controller: $e');
              _pdfController = null;
            }
          }
          _isLoading = false;
        });
      } else {
        print('Failed to load file. Status code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load file: ${response.statusCode}')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('An error occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        backgroundColor: Colors.blue[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isImage
              ? Center(
                  child: _localFilePath != null
                      ? Image.file(File(_localFilePath!))
                      : const Text('Failed to load image'),
                )
              : _localFilePath != null && _pdfController != null
                  ? PdfView(
                      controller: _pdfController!,
                    )
                  : const Center(
                      child: Text('Failed to preview the file'),
                    ),
    );
  }
}
