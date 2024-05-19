import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'File Explorer',
      home: FileExplorerScreen(),
    );
  }
}

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  _FileExplorerScreenState createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  Directory? _currentDirectory;
  final List<Directory> _history = []; // Stores previous directories
  String _currentPath = "";
  bool isEditingPath = false;
  final TextEditingController _newFolderNameController =
      TextEditingController();

  bool _isCreatingNewFolder = false;

  List<Map<String, dynamic>> drives = [];

  void _createFolder() async {
    try {
      String newFolderName = _newFolderNameController.text.trim();
      if (newFolderName.isNotEmpty) {
        final newDir = Directory(_currentDirectory!.path + '/' + newFolderName);
        Directory created = await newDir.create();
        setState(() {
          // _currentDirectory = newDir;
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
  void initState() {
    super.initState();
    _getCurrentDirectory();
    _getWinodwsDrives();
  }

  void _getWinodwsDrives() async {
    try {
      final _drives = await getDrivesOnWindows();
      setState(() {
        drives = _drives;
      });
    } catch (e) {
      // Handle error
      print("Error getting drives: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getDrivesOnWindows() async {
    List<Map<String, dynamic>> drives = [];
    ProcessResult result = await Process.run('powershell',
        ['[System.IO.DriveInfo]::GetDrives()'], stdoutEncoding: const Utf8Codec(),);

        if (result.exitCode == 0) {
      String output = result.stdout;
      List<String> lines = output.split('\n');
      Map<String, dynamic> currentDrive = {};

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) {
          if (currentDrive.isNotEmpty) {
            currentDrive['Name'] = currentDrive['Name'].replaceAll('\\', '');
            drives.add(currentDrive);
            currentDrive = {};
          }
        } else {
          int separatorIndex = line.indexOf(':');
          if (separatorIndex != -1) {
            String key = line.substring(0, separatorIndex).trim();
            String value = line.substring(separatorIndex + 1).trim();
            currentDrive[key] = value;
          }
        }
      }
      if (currentDrive.isNotEmpty) {
        currentDrive['Name'] = currentDrive['Name'].replaceAll('\\', '');
        drives.add(currentDrive);
      }
    }
    return drives;
  }

  Future<void> _getCurrentDirectory() async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      setState(() {
        _currentDirectory = appDocDir;
        _currentPath = appDocDir.path;
      });
    } catch (e) {
      // Handle error
      print("Error getting directory: $e");
    }
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
    return Scaffold(
      appBar: AppBar(
        // title: Text('File Explorer'),
        title: Container(
          // width: MediaQuery.of(context).size.width,
          child: Row(
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
                onPressed: () => setState(() => _isCreatingNewFolder = true),
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
                    try {
                      Directory newDir = Directory(value);
                      bool exists = await newDir.exists();
                      if (exists) {
                        setState(() {
                          _history.add(_currentDirectory!);
                          _currentDirectory = newDir;
                          _currentPath = value;
                        });
                      } else {
                        // Handle invalid path (e.g., snackbar)
                        print("Invalid path: $value");
                      }
                    } catch (e) {
                      // Handle error (e.g., snackbar)
                      print("Error navigating to directory: $e");
                    }
                  },
                ),
              ),
              IconButton(
                  icon: Icon(Icons.vertical_align_top), onPressed: _goUp),
            ],
          ),
        ),
        // bottom: PreferredSize(
        //   preferredSize: Size.fromHeight(30.0),
        //   child:
        // ),
      ),
      body: _currentDirectory == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (drives.isNotEmpty)
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        for (var drive in drives)
                          Expanded(
                            child: ListTile(
                              title:
                                  Text('${drive['VolumeLabel']} (${drive['Name']})'),
                              leading: Icon(Icons.drive_file_rename_outline),
                              onTap: () {
                                setState(() {
                                  _currentDirectory =
                                      Directory(drive['Name']);
                                  _currentPath = drive['Name'];
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  flex: 9,
                  child: ListView.builder(
                    itemCount: _currentDirectory!.listSync().length +
                        (_isCreatingNewFolder ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _isCreatingNewFolder) {
                        return ListTile(
                          title: TextField(
                            controller: _newFolderNameController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter folder name',
                            ),
                            onSubmitted: (_) => _createFolder(),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.check),
                            onPressed: _createFolder,
                          ),
                        );
                      } else {
                        int adjustedIndex =
                            index - (_isCreatingNewFolder ? 1 : 0);
                        FileSystemEntity entity =
                            _currentDirectory!.listSync()[adjustedIndex];
                        return ListTile(
                          title: Text(
                              entity.path.split('/').last.split(r'\').last),
                          leading: Icon(_getIcon(entity)),
                          onTap: () {
                            if (entity is Directory) {
                              setState(() {
                                _history.add(_currentDirectory!);
                                _currentDirectory = entity;
                                _currentPath = entity.path;
                              });
                            } else {
                              OpenFilex.open(entity.path);
                            }
                          },
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
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





// // Get drive letters
    // final driveLettersResult = await Process.run(
    //   'wmic',
    //   ['logicaldisk', 'get', 'caption'],
    //   stdoutEncoding: const SystemEncoding(),
    // );
    // final driveLetters = LineSplitter.split(driveLettersResult.stdout as String)
    //     .map((string) => string.trim())
    //     .where((string) => string.isNotEmpty)
    //     .skip(1)
    //     .toList();

    // // Process drives in parallel
    // final futures = driveLetters.map((drive) async {
    //   final driveLetter = drive.replaceAll(':', '');
    //   final labelResult = await Process.run(
    //     'powershell',
    //     ['Get-Volume', '-DriveLetter', driveLetter],
    //     stdoutEncoding: const Utf8Codec(),
    //   );
    //   final output = labelResult.stdout as String;
    //   final lines = LineSplitter.split(output)
    //       .map((string) => string.trim())
    //       .where((string) => string.isNotEmpty)
    //       .toList();

    //   if (lines.length > 2) {
    //     final columns = lines[2].split(RegExp(r'\s+'));
    //     final friendlyName = columns[1];
    //     return {
    //       'drive': drive,
    //       'label': friendlyName.isEmpty ? 'No Label' : friendlyName
    //     };
    //   } else {
    //     return {'drive': drive, 'label': 'No Label'};
    //   }
    // });

    // final drivesInfo = await Future.wait(futures);
    // return drivesInfo;