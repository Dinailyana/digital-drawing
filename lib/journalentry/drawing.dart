import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController entryNameController = TextEditingController();
  final TextEditingController journalController = TextEditingController();

  final int gridSize = 16;
  late List<List<Color>> pixelColors;
  Color selectedColor = Colors.black;
  List<Color> recentColors = [];

  bool isBold = false;
  bool isItalic = false;
  bool isUnderlined = false;

  int? selectedEmoji; 

  @override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  pixelColors = List.generate(gridSize, (_) => List.generate(gridSize, (_) => Colors.white));
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final args = ModalRoute.of(context)?.settings.arguments;
  if (args != null && args is Map<String, dynamic>) {
    setState(() {
      selectedEmoji = args['beforeStressLevel'] as int?;
    });
  }
}

  void updateSelectedColor(Color color) {
    setState(() {
      selectedColor = color;
      recentColors.remove(color);
      recentColors.insert(0, color);
      if (recentColors.length > 5) recentColors.removeLast();
    });
  }

  void navigateToCancel() {
    Navigator.pushNamed(context, '/cancel', arguments: entryNameController.text);
  }

  Future<void> submitEntry() async {
    if (entryNameController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title for your entry.")),
      );
      return;
    }

    List<String> drawingData = pixelColors.expand((row) => row).map((color) {
      return color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    }).toList();

    try {
      final docRef = await FirebaseFirestore.instance.collection('journalEntries').add({
        'entryTitle': entryNameController.text,
        'journalText': journalController.text,
        'drawingData': drawingData,
        'beforeStressLevel': selectedEmoji, 
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushNamed(
        context,
       '/endprompt',   
        arguments: {
          'docId': docRef.id,
          'beforeStressLevel': selectedEmoji,
        },
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry submitted!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit entry: $e")),
      );
    }
  }

  void insertPrompt(String prompt) {
    journalController.text += "\n=== $prompt ===\n";
    journalController.selection = TextSelection.collapsed(offset: journalController.text.length);
  }

  TextStyle _getTextStyle() {
    return TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF8E97FD);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        leading: BackButton(onPressed: navigateToCancel, color: Colors.black),
        title: TextField(
          controller: entryNameController,
          decoration: const InputDecoration(
            hintText: "Entry Title",
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: purple,
          unselectedLabelColor: Colors.black,
          indicatorColor: purple,
          tabs: const [
            Tab(text: "Drawing"),
            Tab(text: "Journal"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Drawing Tab
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    itemCount: gridSize * gridSize,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                    ),
                    itemBuilder: (context, index) {
                      int row = index ~/ gridSize;
                      int col = index % gridSize;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            pixelColors[row][col] = selectedColor;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.all(0.5),
                          decoration: BoxDecoration(
                            color: pixelColors[row][col],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Color tempColor = selectedColor;
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Pick a color"),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: tempColor,
                                onColorChanged: (color) => tempColor = color,
                                pickerAreaHeightPercent: 0.8,
                                enableAlpha: false,
                                displayThumbColor: true,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  updateSelectedColor(tempColor);
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text("Select"),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text("Open Color Wheel"),
                    ),
                    const SizedBox(height: 8),
                    const Text("Recent Colors", style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        children: recentColors.map((color) {
                          return GestureDetector(
                            onTap: () => updateSelectedColor(color),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor == color ? Colors.black : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => updateSelectedColor(Colors.white),
                      icon: const Icon(Icons.cleaning_services),
                      label: const Text("Eraser"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Journal Tab
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: ["goal", "mood", "thoughts", "plans", "gratitude", "dreams"]
                        .map((prompt) => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: purple,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () => insertPrompt(prompt),
                              child: Text(prompt, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(isBold ? Icons.format_bold : Icons.format_bold_outlined, color: purple),
                        onPressed: () => setState(() => isBold = !isBold),
                      ),
                      IconButton(
                        icon: Icon(isItalic ? Icons.format_italic : Icons.format_italic_outlined, color: purple),
                        onPressed: () => setState(() => isItalic = !isItalic),
                      ),
                      IconButton(
                        icon: Icon(isUnderlined ? Icons.format_underline : Icons.format_underline_outlined, color: purple),
                        onPressed: () => setState(() => isUnderlined = !isUnderlined),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: TextField(
                      controller: journalController,
                      maxLines: null,
                      style: _getTextStyle(),
                      decoration: const InputDecoration.collapsed(
                        hintText: "Write your journal here...",
                      ),
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: submitEntry,
          style: ElevatedButton.styleFrom(
            backgroundColor: purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          child: const Text("Submit Entry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
