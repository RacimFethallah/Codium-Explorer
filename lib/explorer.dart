import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as FluentUI;
import 'package:open_filex/open_filex.dart';

class Explorer extends StatefulWidget {
  final Directory currentDirectory;
  final String currentPath;

  const Explorer(
      {super.key, required this.currentDirectory, required this.currentPath});

  @override
  State<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends State<Explorer> {
  late Directory _currentDirectory;
  late String _currentPath;
  final List<Directory> _history = [];
  bool isEditingPath = false;
  final TextEditingController _newFolderNameController =
      TextEditingController();

  bool _isCreatingNewFolder = false;

  @override
  void initState() {
    super.initState();
    _currentDirectory = widget.currentDirectory;
    _currentPath = widget.currentPath;
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      setState(() {
        _currentDirectory = _history.removeLast();
        _currentPath = _currentDirectory.path;
      });
    }
  }

  void _goForward() {
    // Implement logic to go forward if there are entries in history
  }

  void _goUp() {
    if (_currentDirectory.parent.path != Directory.current.path) {
      setState(() {
        _history.add(_currentDirectory);
        _currentDirectory = _currentDirectory.parent;
        _currentPath = _currentDirectory.path;
      });
    }
  }

  void _refresh() async {
    if (_currentPath.isNotEmpty) {
      try {
        Directory newDir = Directory(_currentPath);
        bool exists = await newDir.exists();
        if (exists) {
          setState(() {
            _currentDirectory = newDir;
          });
        } else {
          // Handle invalid path
          print("Invalid path: $_currentPath");
        }
      } catch (e) {
        // Handle error
        print("Error refreshing directory: $e");
      }
    }
  }

  void _createFolder() async {
    try {
      String newFolderName = _newFolderNameController.text.trim();
      if (newFolderName.isNotEmpty) {
        final newDir = Directory(_currentDirectory.path + '/' + newFolderName);
        await newDir.create();
        setState(() {
          _isCreatingNewFolder = false;
          _newFolderNameController.text = ""; // Clear text field
          _refresh();
        });
      }
    } catch (e) {
      // Handle exception (e.g., snackbar)
      print("Error creating folder: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Row(
              children: [
                FluentUI.IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _goBack,
                ),
                FluentUI.IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: _goForward, // Corrected from _goBack to _goForward
                ),
                FluentUI.IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
                FluentUI.IconButton(
                  icon: Icon(Icons.create_new_folder),
                  onPressed: () {
                    setState(() {
                      _isCreatingNewFolder = true;
                    });
                  },
                ),
                Expanded(
                  child: FluentUI.TextBox(
                    controller: TextEditingController(text: _currentPath),
                    onSubmitted: (value) async {
                      // Handle path submission logic here
                    },
                  ),
                ),
                FluentUI.IconButton(
                  icon: Icon(Icons.vertical_align_top),
                  onPressed: _goUp,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                child: Column(
                  children: [
                    if (_isCreatingNewFolder)
                      FluentUI.ListTile(
                        title: FluentUI.TextBox(
                          controller: _newFolderNameController,
                          autofocus: true,
                          onSubmitted: (_) => _createFolder(),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.check),
                          onPressed: _createFolder,
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _currentDirectory.listSync().length,
                        itemBuilder: (context, index) {
                          FileSystemEntity entity =
                              _currentDirectory.listSync()[index];
                          return FluentUI.ListTile.selectable(
                            title: Text(
                                entity.path.split('/').last.split(r'\').last),
                            leading: Icon(_getIcon(entity)),
                            onPressed: () {
                              if (entity is Directory) {
                                setState(() {
                                  _history.add(_currentDirectory);
                                  _currentDirectory = entity;
                                  _currentPath = entity.path;
                                });
                              } else {
                                OpenFilex.open(entity.path);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20, // Adjust as needed
          left: 20,
          right: 20,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  30.0), // Adjust the corner radius as needed
              child: Container(
                color: const Color.fromARGB(255, 255, 255, 255),
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                child: IntrinsicWidth(
                  child: Row(
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_icons.length, (index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal:
                                12.0), // Adjust the spacing between icons
                        child: IconButton(
                          icon: Icon(_icons[index].icon),
                          onPressed: _icons[index].onPressed,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIcon(FileSystemEntity entity) {
    if (entity is Directory) {
      return Icons.folder;
    } else if (entity is File) {
      return Icons.insert_drive_file;
    } else {
      return Icons.insert_drive_file; // Default icon
    }
  }
}

class IconItem {
  final IconData icon;
  final VoidCallback onPressed;

  IconItem({required this.icon, required this.onPressed});
}

// Example icons list
final List<IconItem> _icons = [
  IconItem(
    icon: Icons.home,
    onPressed: () {
    },
  ),
  IconItem(
    icon: Icons.search,
    onPressed: () {
      // Search icon action
    },
  ),
  IconItem(
    icon: Icons.settings,
    onPressed: () {
      // Settings icon action
    },
  ),
];
