import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:window_manager/window_manager.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:system_theme/system_theme.dart';
import 'package:fluent_ui/fluent_ui.dart' as FluentUI;

import 'explorer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false, //permet de ne pas l'afficher dans la barre des taches
    titleBarStyle: TitleBarStyle.hidden,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FluentUI.FluentApp(
      theme: FluentUI.FluentThemeData(
        accentColor: SystemTheme.accentColor.accent.toAccentColor(),
      ),
      debugShowCheckedModeBanner: false,
      title: 'File Explorer',
      home: FileExplorerScreen(),
    );
  }
}

class QuickAccessItem {
  final Icon icon;
  final String name;

  QuickAccessItem({required this.icon, required this.name});
}

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({super.key});

  @override
  _FileExplorerScreenState createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen>
    with WindowListener {
  Directory? _currentDirectory;
  final List<Directory> _history = []; // Stores previous directories
  String _currentPath = 'Home';  // Default to home
  bool isEditingPath = false;
  final TextEditingController _newFolderNameController =
      TextEditingController();

  bool _isCreatingNewFolder = false;

  List<Map<String, dynamic>> drives = [];

  static List<QuickAccessItem> quickAccessItems = [
    // Replace with your actual icon data or use libraries like Font Awesome
    QuickAccessItem(icon: Icon(FluentUI.FluentIcons.this_p_c), name: 'Desktop'),
    QuickAccessItem(
        icon: Icon(FluentUI.FluentIcons.documentation), name: 'Documents'),
    QuickAccessItem(
        icon: Icon(FluentUI.FluentIcons.download), name: 'Downloads'),
    QuickAccessItem(
        icon: Icon(FluentUI.FluentIcons.picture_center), name: 'Images'),
    QuickAccessItem(
        icon: Icon(FluentUI.FluentIcons.music_in_collection), name: 'Music'),
    QuickAccessItem(
        icon: Icon(FluentUI.FluentIcons.my_movies_t_v), name: 'Videos'),
  ];

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
    windowManager.addListener(this);
    // _getCurrentDirectory();
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
    ProcessResult result = await Process.run(
      'powershell',
      ['[System.IO.DriveInfo]::GetDrives()'],
      stdoutEncoding: const Utf8Codec(),
    );

    if (result.exitCode == 0) {
      String output = result.stdout;
      List<String> lines = output.split('\n');
      Map<String, dynamic> currentDrive = {};

      for (String line in lines) {
        line = line.trim();
        if (line.isEmpty) {
          if (currentDrive.isNotEmpty) {
            currentDrive['Name'] = currentDrive['Name'].replaceAll('\\', '');
            currentDrive['TotalSize'] =
                double.parse(currentDrive['TotalSize']) / (1024 * 1024 * 1024);

            currentDrive['TotalFreeSpace'] =
                double.parse(currentDrive['TotalFreeSpace']) /
                    (1024 * 1024 * 1024);
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
        currentDrive['TotalSize'] =
            double.parse(currentDrive['TotalSize']) / (1024 * 1024 * 1024);
        currentDrive['TotalFreeSpace'] =
            double.parse(currentDrive['TotalFreeSpace']) / (1024 * 1024 * 1024);
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
    int crossAxisCount = MediaQuery.of(context).size.width ~/ 180;
    int crossAxisCountDrives = MediaQuery.of(context).size.width ~/ 300;
    return GlassContainer.clearGlass(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Color.fromARGB(220, 255, 255, 255),
      child: FluentUI.ScaffoldPage(
        padding: EdgeInsets.zero,
        header: AppBar(
          flexibleSpace: shortLongPress(
            duration: const Duration(milliseconds: 0),
            onLongPress: () {
              windowManager.startDragging();
            },
            child: Container(
              height: 40,
              color: Colors.transparent,
            ),
          ),
          backgroundColor: Colors.transparent,
          title: Row(
            children: [
              Container(
                width: 200,
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(200, 255, 255, 255),
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(FluentUI.FluentIcons.home, size: 16),
                    SizedBox(width: 10),
                    Text(
                      'Home',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(200, 255, 255, 255),
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Row(
                  children: [
                    FluentUI.IconButton(
                        onPressed: () {
                          windowManager.minimize();
                        },
                        icon: Icon(FluentUI.FluentIcons.chevron_down_end,
                            size: 14)),
                    SizedBox(width: 18),
                    FluentUI.IconButton(
                        onPressed: () async {
                          await windowManager.isMaximized()
                              ? windowManager.unmaximize()
                              : windowManager.maximize();
                        },
                        icon: const Icon(FluentUI.FluentIcons.circle_ring,
                            size: 14)),
                    SizedBox(width: 18),
                    FluentUI.IconButton(
                      onPressed: () {
                        windowManager.close();
                      },
                      icon: const Icon(
                        FluentUI.FluentIcons.cancel,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        content:_currentPath == 'Home'
            ? home(crossAxisCount, crossAxisCountDrives)
             : Explorer(currentDirectory: _currentDirectory!, currentPath: _currentPath),
      ),
    );
  }



  SingleChildScrollView home(int crossAxisCount, int crossAxisCountDrives) {
    return SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
              child: Row(
                children: [
                  Text('Home',
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w400)),
                  Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FluentUI.Expander(
                contentBackgroundColor: Color.fromARGB(150, 255, 255, 255),
                headerBackgroundColor: FluentUI.ButtonState.all(
                    const Color.fromARGB(200, 255, 255, 255)),
                initiallyExpanded: true,
                header: Text('Quick Access'),
                content: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 1.3,
                    crossAxisCount:
                        crossAxisCount, // number of items in each row
                    mainAxisSpacing: 12.0, // spacing between rows
                    crossAxisSpacing: 10.0, // spacing between columns
                  ),
                  padding: EdgeInsets.zero, // padding around the grid
                  itemCount: quickAccessItems.length, // total number of items
                  itemBuilder: (context, index) {
                    final item = quickAccessItems[index];
                    return FluentUI.ListTile.selectable(
                      cursor: SystemMouseCursors.click,
                      selectionMode: FluentUI.ListTileSelectionMode.single,
                      tileColor: FluentUI.ButtonState.all(
                          const Color.fromARGB(200, 255, 255, 255)),
                      // width: 20,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          item.icon,
                          SizedBox(
                            height: 20,
                          ),
                          Center(
                            child: Text(
                              item.name,
                              style: TextStyle(fontSize: 18.0),
                              textAlign: TextAlign
                                  .center, // Center text horizontally
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
              child: FluentUI.Expander(
                contentBackgroundColor: Color.fromARGB(150, 255, 255, 255),
                headerBackgroundColor: FluentUI.ButtonState.all(
                    const Color.fromARGB(200, 255, 255, 255)),
                initiallyExpanded: true,
                header: Text('Drives'),
                content: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    childAspectRatio: 2.5,
                    crossAxisCount:
                        crossAxisCountDrives, // number of items in each row
                    mainAxisSpacing: 12.0, // spacing between rows
                    crossAxisSpacing: 10.0, // spacing between columns
                  ),
                  padding: EdgeInsets.zero, // padding around the grid
                  itemCount: drives.length, // total number of items
                  itemBuilder: (context, index) {
                    final drive = drives[index];
                    return FluentUI.ListTile.selectable(
                      cursor: SystemMouseCursors.click,
                      selectionMode: FluentUI.ListTileSelectionMode.single,
                      tileColor: FluentUI.ButtonState.all(
                          const Color.fromARGB(200, 255, 255, 255)),
                      title: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        // Use Stack for overlapping widgets
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(FluentUI.FluentIcons.hard_drive, size: 20),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                  '${drive['VolumeLabel']} (${drive['Name']})'),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          FluentUI.ProgressBar(
                            value: 100.0 -
                                (drive['TotalFreeSpace'] *
                                    100 /
                                    drive['TotalSize']),
                            activeColor: Colors.blue.shade600,
                            // valueColor: AlwaysStoppedAnimation(Colors.blue),
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                              '${drive['TotalFreeSpace'].toStringAsFixed(1)} GB Free of ${drive['TotalSize'].toStringAsFixed(1)} GB'),
                        ],
                      ),
                      onPressed: () {
                        setState(() {
                          _currentDirectory = Directory(drive['Name']);
                          _currentPath = drive['Name'];
                        });
                      },
                    );
                  },
                ),
              ),
            )
          ],
        ),
      );
  }
}

class shortLongPress extends StatelessWidget {
  final Widget? child;
  final Duration duration;
  final VoidCallback onLongPress;

  const shortLongPress({
    super.key,
    this.child,
    required this.duration,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: duration),
          (instance) => instance.onLongPress = onLongPress,
        ),
      },
      child: child,
    );
  }
}

// IconButton(
//               icon: Icon(Icons.arrow_back),
//               onPressed: _goBack,
//               disabledColor: Colors.grey, // Disable if no history
//             ),
//             IconButton(
//               icon: Icon(Icons.arrow_forward),
//               onPressed: _goBack,
//               disabledColor: Colors.grey, // Disable if no history
//             ),
//             IconButton(icon: Icon(Icons.refresh), onPressed: _refresh),
//             IconButton(
//               icon: Icon(Icons.create_new_folder),
//               onPressed: () => setState(() => _isCreatingNewFolder = true),
//             ),
//             Expanded(
//               child: TextField(
//                 controller: TextEditingController(text: _currentPath),
//                 decoration: const InputDecoration(
//                   // filled: true,
//                   // fillColor: Colors.blue,
//                   border: OutlineInputBorder(
//                     // borderSide: BorderSide.none,
//                     borderRadius: BorderRadius.all(Radius.circular(100.0)),
//                   ),
//                 ),
//                 onSubmitted: (value) async {
//                   try {
//                     Directory newDir = Directory(value);
//                     bool exists = await newDir.exists();
//                     if (exists) {
//                       setState(() {
//                         _history.add(_currentDirectory!);
//                         _currentDirectory = newDir;
//                         _currentPath = value;
//                       });
//                     } else {
//                       // Handle invalid path (e.g., snackbar)
//                       print("Invalid path: $value");
//                     }
//                   } catch (e) {
//                     // Handle error (e.g., snackbar)
//                     print("Error navigating to directory: $e");
//                   }
//                 },
//               ),
//             ),
//             IconButton(
//                 icon: Icon(Icons.vertical_align_top), onPressed: _goUp),

// _currentDirectory == null
//           ? Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 if (drives.isNotEmpty)
//                   Expanded(
//                     flex: 1,
//                     child: Row(
//                       children: [
//                         for (var drive in drives)
//                           Expanded(
//                             child: ListTile(
//                               title: Text(
//                                   '${drive['VolumeLabel']} (${drive['Name']})'),
//                               subtitle: Column(
//                                 children: [
//                                   LinearProgressIndicator(
//                                     value: 1.0 -
//                                         (drive['TotalFreeSpace'] / drive['TotalSize']),
//                                     valueColor:
//                                         AlwaysStoppedAnimation(Colors.blue),
//                                   ),
//                                   Text(
//                                       '${drive['TotalFreeSpace'].toStringAsFixed(1)} GB Free of ${drive['TotalSize'].toStringAsFixed(1)} GB'),
//                                 ],
//                               ),
//                               leading: Icon(Icons.drive_file_rename_outline),
//                               onTap: () {
//                                 setState(() {
//                                   _currentDirectory = Directory(drive['Name']);
//                                   _currentPath = drive['Name'];
//                                 });
//                               },
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),
//                 Expanded(
//                   flex: 9,
//                   child: ListView.builder(
//                     itemCount: _currentDirectory!.listSync().length +
//                         (_isCreatingNewFolder ? 1 : 0),
//                     itemBuilder: (context, index) {
//                       if (index == 0 && _isCreatingNewFolder) {
//                         return ListTile(
//                           title: TextField(
//                             controller: _newFolderNameController,
//                             autofocus: true,
//                             decoration: const InputDecoration(
//                               hintText: 'Enter folder name',
//                             ),
//                             onSubmitted: (_) => _createFolder(),
//                           ),
//                           trailing: IconButton(
//                             icon: Icon(Icons.check),
//                             onPressed: _createFolder,
//                           ),
//                         );
//                       } else {
//                         int adjustedIndex =
//                             index - (_isCreatingNewFolder ? 1 : 0);
//                         FileSystemEntity entity =
//                             _currentDirectory!.listSync()[adjustedIndex];
//                         return ListTile(
//                           title: Text(
//                               entity.path.split('/').last.split(r'\').last),
//                           leading: Icon(_getIcon(entity)),
//                           onTap: () {
//                             if (entity is Directory) {
//                               setState(() {
//                                 _history.add(_currentDirectory!);
//                                 _currentDirectory = entity;
//                                 _currentPath = entity.path;
//                               });
//                             } else {
//                               OpenFilex.open(entity.path);
//                             }
//                           },
//                         );
//                       }
//                     },
//                   ),
//                 ),
//               ],
//             ),

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
