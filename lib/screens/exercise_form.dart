import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;

/// Data model for one exercise row.
class ExerciseRowData {
  final TextEditingController sectionController;
  final TextEditingController exerciseNameController;
  final TextEditingController modificationController;
  final TextEditingController durationController;
  Color selectedColor;

  ExerciseRowData({
    String initialSection = '',
    String initialExerciseName = '',
    String initialModification = '',
    String initialDuration = '',
    Color? initialColor,
  })  : sectionController = TextEditingController(text: initialSection),
        exerciseNameController = TextEditingController(text: initialExerciseName),
        modificationController = TextEditingController(text: initialModification),
        durationController = TextEditingController(text: initialDuration),
        selectedColor = initialColor ?? Colors.grey;

  void dispose() {
    sectionController.dispose();
    exerciseNameController.dispose();
    modificationController.dispose();
    durationController.dispose();
  }

  String get colorString =>
      "(${selectedColor.red},${selectedColor.green},${selectedColor.blue})";

  // Create a duplicate (deep copy) of this row.
  ExerciseRowData duplicate() {
    return ExerciseRowData(
      initialSection: sectionController.text,
      initialExerciseName: exerciseNameController.text,
      initialModification: modificationController.text,
      initialDuration: durationController.text,
      initialColor: selectedColor,
    );
  }
}

class ExerciseBuilderTable extends StatefulWidget {
  const ExerciseBuilderTable({Key? key}) : super(key: key);

  @override
  State<ExerciseBuilderTable> createState() => _ExerciseBuilderTableState();
}

class _ExerciseBuilderTableState extends State<ExerciseBuilderTable>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for table rows.
  final List<ExerciseRowData> warmupRows = [];
  final List<ExerciseRowData> cooldownRows = [];
  final Map<int, List<ExerciseRowData>> roundRows = {};

  // Controller for the user-defined video name.
  final TextEditingController _videoNameController = TextEditingController();

  // For Round tab: track which round is selected.
  int selectedRound = 1;
  int maxRound = 1;

  late TabController _tabController;
  final double _rowHeight = 80.0;


  // NEW: API base URL from dart-define
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');

  @override
  void initState() {
    super.initState();
    // Initialize with one row for Warmup and Cooldown.
    warmupRows.add(ExerciseRowData(initialSection: "Warmup"));
    cooldownRows.add(ExerciseRowData(initialSection: "Cooldown"));
    // Initialize Round 1.
    roundRows[1] = [ExerciseRowData(initialSection: "Round 1")];
    maxRound = 1;
    selectedRound = 1;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    // Dispose all row controllers.
    for (var row in warmupRows) row.dispose();
    for (var row in cooldownRows) row.dispose();
    for (var list in roundRows.values) {
      for (var row in list) row.dispose();
    }
    // Dispose the video name controller.
    _videoNameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Generate workout data in a format that the API expects.
  List<List<dynamic>> _generateWorkoutData() {
    final List<List<dynamic>> workoutData = [];

    void processRow(ExerciseRowData row) {
      if (row.sectionController.text.isNotEmpty &&
          row.exerciseNameController.text.isNotEmpty &&
          row.durationController.text.isNotEmpty) {
        workoutData.add([
          row.sectionController.text,
          row.exerciseNameController.text,
          row.modificationController.text,
          [row.selectedColor.red, row.selectedColor.green, row.selectedColor.blue],
          int.tryParse(row.durationController.text) ?? 0,
        ]);
      }
    }

    for (var row in warmupRows) processRow(row);
    for (int r = 1; r <= maxRound; r++) {
      for (var row in (roundRows[r] ?? [])) {
        processRow(row);
      }
    }
    for (var row in cooldownRows) processRow(row);

    return workoutData;
  }

  /// Sends the workout data (and video name) to the FastAPI backend.
  Future<void> _submitExercises() async {
    final workoutData = _generateWorkoutData();

    // Use user-defined base name (without extension), or null to fallback.
    final rawName = _videoNameController.text.trim();
    final String? videoName = rawName.isEmpty ? null : rawName;

    final Uri url = Uri.parse('$baseUrl/generate-video');

    final Map<String, dynamic> bodyData = {
      'workout': workoutData,
      'video_name': videoName,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Success!"),
            content: Text("Video generated and available in library!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: Text(
              "Failed to generate video:\nStatus ${response.statusCode}\n${response.body}",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Exception"),
          content: Text("An error occurred:\n$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  // … Insert your existing _buildTableHeader, _buildRow, and _buildReorderableTable methods here …

  Widget _buildTableHeader() {
    return Container(
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: const [
          Expanded(child: Text("Section", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Exercise", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Modification", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Duration", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text("Color", style: TextStyle(fontWeight: FontWeight.bold))),
          SizedBox(width: 50, child: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRow(ExerciseRowData row, int index, VoidCallback onDelete, VoidCallback onDuplicate) {
    return Container(
      key: ValueKey(index),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: row.sectionController,
              decoration: const InputDecoration(hintText: "Section"),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row.exerciseNameController,
              decoration: const InputDecoration(hintText: "Exercise"),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row.modificationController,
              decoration: const InputDecoration(hintText: "Modification"),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: row.durationController,
              decoration: const InputDecoration(hintText: "Duration"),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Color tempColor = row.selectedColor;
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Select a Color"),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ColorPicker(
                            pickerColor: tempColor,
                            onColorChanged: (color) {
                              tempColor = color;
                            },
                            enableAlpha: false,
                            displayThumbColor: true,
                            paletteType: PaletteType.hsv,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "RGB: (${tempColor.red}, ${tempColor.green}, ${tempColor.blue})",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            row.selectedColor = tempColor;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text("Done"),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: row.selectedColor,
                  border: Border.all(color: Colors.black),
                ),
                child: Text(
                  "RGB: ${row.colorString}",
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: "Duplicate Row",
                  onPressed: onDuplicate,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: "Delete Row",
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReorderableTable(
    List<ExerciseRowData> rows,
    VoidCallback onAddRow,
    Function(int) onRemoveRow,
    Function(int) onDuplicateRow,
  ) {
    double containerHeight = (rows.length * _rowHeight) + 20;
    return Column(
      children: [
        _buildTableHeader(),
        const SizedBox(height: 8),
        SizedBox(
          height: containerHeight,
          child: ReorderableListView(
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final row = rows.removeAt(oldIndex);
                rows.insert(newIndex, row);
              });
            },
            children: List.generate(rows.length, (index) {
              return Container(
                key: ValueKey(index),
                child: _buildRow(
                  rows[index],
                  index,
                  () {
                    rows[index].dispose();
                    setState(() => rows.removeAt(index));
                  },
                  () {
                    setState(() => rows.insert(index + 1, rows[index].duplicate()));
                  },
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onAddRow,
          child: const Text("Add Row"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exercise Builder Table"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Warmup"),
            Tab(text: "Round"),
            Tab(text: "Cooldown"),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  SingleChildScrollView(
                    child: _buildReorderableTable(
                      warmupRows,
                      () => setState(() => warmupRows.add(ExerciseRowData(initialSection: "Warmup"))),
                      (i) => setState(() {
                        warmupRows[i].dispose();
                        warmupRows.removeAt(i);
                      }),
                      (i) => setState(() => warmupRows.insert(i + 1, warmupRows[i].duplicate())),
                    ),
                  ),
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text("Select Round: "),
                            DropdownButton<int>(
                              value: selectedRound,
                              items: List.generate(maxRound, (i) {
                                final round = i + 1;
                                return DropdownMenuItem(
                                  value: round,
                                  child: Text("Round $round"),
                                );
                              }),
                              onChanged: (v) {
                                if (v != null) setState(() => selectedRound = v);
                              },
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  maxRound++;
                                  roundRows[maxRound] = [];
                                  selectedRound = maxRound;
                                });
                              },
                              child: const Text("Add New Round"),
                            ),
                          ],
                        ),
                        _buildReorderableTable(
                          roundRows[selectedRound]!,
                          () => setState(() => roundRows[selectedRound]!
                              .add(ExerciseRowData(initialSection: "Round $selectedRound"))),
                          (i) => setState(() {
                            roundRows[selectedRound]![i].dispose();
                            roundRows[selectedRound]!.removeAt(i);
                          }),
                          (i) => setState(() =>
                              roundRows[selectedRound]!.insert(i + 1, roundRows[selectedRound]![i].duplicate())),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    child: _buildReorderableTable(
                      cooldownRows,
                      () => setState(() => cooldownRows.add(ExerciseRowData(initialSection: "Cooldown"))),
                      (i) => setState(() {
                        cooldownRows[i].dispose();
                        cooldownRows.removeAt(i);
                      }),
                      (i) => setState(() => cooldownRows.insert(i + 1, cooldownRows[i].duplicate())),
                    ),
                  ),
                ],
              ),
            ),
           // Video name input
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: TextFormField(
               controller: _videoNameController,
               decoration: const InputDecoration(
                 labelText: 'Video Name',
                 hintText: 'Enter a name (without .mp4)',
                 border: OutlineInputBorder(),
               ),
             ),
           ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitExercises,
              child: const Text("Submit & Generate Video"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: ExerciseBuilderTable(),
  ));
}
