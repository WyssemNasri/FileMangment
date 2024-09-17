import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'FilePreviewScreen.dart';
import 'Constant.dart';

class FolderContentsScreen extends StatefulWidget {
  final String folderId;
  final String folderName;

  const FolderContentsScreen({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  @override
  _FolderContentsScreenState createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse('$endpoint/${widget.folderId}/files');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> fetchedItems = json.decode(response.body);
        setState(() {
          _items = fetchedItems;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load items: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(String fileId, String fileName) async {
    try {
      final uri = Uri.parse('$endpoint/files/$fileId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File downloaded: ${file.path}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download file: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  void _showFilePreview(String fileId, String fileName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FilePreviewScreen(fileId: fileId, fileName: fileName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folderName} Files',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _items.isEmpty
                ? const Center(child: Text('No items found'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final itemName = item['filename'] ?? 'Unnamed File';
                      final itemId = item['id']?.toString() ?? 'No ID';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          leading: Icon(Icons.file_copy,
                              size: 40, color: Colors.blue[900]),
                          title: Text(
                            itemName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.download, color: Colors.blue[900]),
                            onPressed: () => _downloadFile(itemId, itemName),
                          ),
                          onTap: () => _showFilePreview(itemId, itemName),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
