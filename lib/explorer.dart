import 'dart:io';

import 'package:flutter/material.dart';

class Explorer extends StatefulWidget {
  final Directory currentDirectory;
  final String currentPath;

  const Explorer({super.key, required this.currentDirectory, required this.currentPath});

  @override
  State<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends State<Explorer> {
    late Directory _currentDirectory;
  late String _currentPath;
  final List<Directory> _history = [];

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
        _currentPath = _currentDirectory!.path;
      });
    }
  }

  void _goForward() {
    // Implement logic to go forward if there are entries in history
  }

  void _goUp() {
    if (_currentDirectory!.parent.path != Directory.current.path) {
      setState(() {
        _currentDirectory = _currentDirectory!.parent;
        _currentPath = _currentDirectory!.path;
        _history.add(_currentDirectory!); // Add current to history
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

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _goBack,
                disabledColor: Colors.grey, // Disable if no history
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: _goBack,
                disabledColor: Colors.grey, // Disable if no history
              ),
              IconButton(icon: Icon(Icons.refresh), onPressed: _refresh),
              IconButton(
                icon: Icon(Icons.create_new_folder),
                // onPressed: () => setState(() => _isCreatingNewFolder = true),
                onPressed: (){},
              ),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _currentPath),
                  decoration: const InputDecoration(
                    // filled: true,
                    // fillColor: Colors.blue,
                    border: OutlineInputBorder(
                      // borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(100.0)),
                    ),
                  ),
                  onSubmitted: (value) async {
                    // try {
                    //   Directory newDir = Directory(value);
                    //   bool exists = await newDir.exists();
                    //   if (exists) {
                    //     setState(() {
                    //       _history.add(_currentDirectory!);
                    //       _currentDirectory = newDir;
                    //       _currentPath = value;
                    //     });
                    //   } else {
                    //     // Handle invalid path (e.g., snackbar)
                    //     print("Invalid path: $value");
                    //   }
                    // } catch (e) {
                    //   // Handle error (e.g., snackbar)
                    //   print("Error navigating to directory: $e");
                    // }
                  },
                ),
              ),
              IconButton(
                  icon: Icon(Icons.vertical_align_top), onPressed: _goUp),
              ],
      
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
              child: Row(
                children: [
                  Text(_currentDirectory.path, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
                  Spacer(),
                ],
              ),
            ),
            // Add more content here based on the directory's content
          ],
        ),
      ),
    );
  }
}