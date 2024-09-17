import 'package:flutter/material.dart';
import 'Constant.dart';
import 'FolderContentsScreen.dart';
import 'UploadFileScreen.dart'; // Import the UploadFileScreen class
import 'package:http/http.dart' as http;
import 'dart:convert';

class FolderManagementScreen extends StatefulWidget {
  const FolderManagementScreen({super.key});

  @override
  _FolderManagementScreenState createState() => _FolderManagementScreenState();
}

class _FolderManagementScreenState extends State<FolderManagementScreen> {
  List<dynamic> _folders = [];
  List<dynamic> _filteredFolders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchFolders();
    _searchController.addListener(_filterFolders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFolders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final uri = Uri.parse(endpoint); // API to get folders
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        setState(() {
          _folders = json.decode(response.body);
          _filteredFolders = _folders;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load folders: ${response.statusCode}')),
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

  void _filterFolders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFolders = _folders.where((folder) {
        final folderName = folder['name']?.toLowerCase() ?? '';
        return folderName.contains(query);
      }).toList();
    });
  }

  void _navigateToFolderContents(String folderId, String folderName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderContentsScreen(
          folderId: folderId,
          folderName: folderName,
        ),
      ),
    );
  }

  void _navigateToUploadFileScreen(String folderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFileScreen(
          folderId: folderId,
        ),
      ),
    );
  }

  Future<void> _createFolder() async {
    final folderNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Folder'),
          content: TextField(
            controller: folderNameController,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final folderName = folderNameController.text.trim();

                if (folderName.isNotEmpty) {
                  try {
                    final uri = Uri.parse(
                        '$endpoint/createFolder'); // API endpoint to create folder
                    final response = await http.post(
                      uri,
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({'name': folderName}),
                    );

                    if (response.statusCode == 201) {
                      _fetchFolders();
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to create folder: ${response.statusCode}')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An error occurred: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Manage Folders', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: _createFolder,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              // This button should open a screen to select the folder and then upload the file
              // Here, you might need to handle folder selection before navigating to UploadFileScreen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Folders',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredFolders.isEmpty
                      ? const Center(child: Text('No folders found'))
                      : ListView.builder(
                          itemCount: _filteredFolders.length,
                          itemBuilder: (context, index) {
                            final folder = _filteredFolders[index];
                            final folderName =
                                folder['name'] ?? 'Unnamed Folder';
                            final folderId =
                                folder['id']?.toString() ?? 'No ID';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              elevation: 5,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                leading: const Icon(Icons.folder,
                                    size: 40, color: Colors.orange),
                                title: Text(
                                  folderName,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                onTap: () => _navigateToFolderContents(
                                    folderId, folderName),
                                trailing: IconButton(
                                  icon: const Icon(Icons.upload_file),
                                  onPressed: () =>
                                      _navigateToUploadFileScreen(folderId),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
