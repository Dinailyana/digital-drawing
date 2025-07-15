import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EachDrawingPage extends StatefulWidget {
  final String entryId;
  const EachDrawingPage({super.key, required this.entryId});

  @override
  State<EachDrawingPage> createState() => _EachDrawingPageState();
}

class _EachDrawingPageState extends State<EachDrawingPage> {
  String? currentUsername;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // Load current user from SharedPreferences
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString('current_username');
    });
  }

  Color getStressColor(int level) {
    switch (level) {
      case 0:
        return Colors.green.shade200;
      case 1:
        return Colors.lightGreen.shade200;
      case 2:
        return Colors.yellow.shade200;
      case 3:
        return Colors.orange.shade200;
      case 4:
        return Colors.red.shade200;
      default:
        return Colors.grey.shade300;
    }
  }

  // New helper to get emoji and label for stress level
  Map<String, String> getStressEmojiAndLabel(int level) {
    switch (level) {
      case 0:
        return {'emoji': '😌', 'label': 'Calm'};
      case 1:
        return {'emoji': '🙂', 'label': 'Relaxed'};
      case 2:
        return {'emoji': '😐', 'label': 'Neutral'};
      case 3:
        return {'emoji': '😟', 'label': 'Stressed'};
      case 4:
        return {'emoji': '😣', 'label': 'Very Stressed'};
      default:
        return {'emoji': '❓', 'label': 'Not recorded'};
    }
  }

  // New method to build the pixel art drawing
  Widget buildPixelArtDrawing(List<dynamic> drawingData) {
    const int gridSize = 16; // Same as in EntryPage
    
    if (drawingData.length != gridSize * gridSize) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text("Invalid drawing data"),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.0, // Square aspect ratio
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling
            itemCount: gridSize * gridSize,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
            ),
            itemBuilder: (context, index) {
              // Convert hex string back to Color
              String hexColor = drawingData[index] as String;
              Color pixelColor;
              try {
                pixelColor = Color(int.parse('0x$hexColor'));
              } catch (e) {
                pixelColor = Colors.white; // Fallback color
              }
              
              return Container(
                decoration: BoxDecoration(
                  color: pixelColor,
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 0.5,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF7F7F7);
    const primaryColor = Color(0xFF71C9CE);
    const textColor = Color(0xFF333333);

    // Wait for currentUsername to load
    if (currentUsername == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: const Text(
            "Your Entry",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "Your Entry",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('journalEntries')
            .doc(widget.entryId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Entry not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // SECURITY CHECK: Verify this entry belongs to the current user
          final entryUserId = data['userId'] as String?;
          if (entryUserId != currentUsername) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Access Denied",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This entry doesn't belong to you.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back"),
                  ),
                ],
              ),
            );
          }

          final journal = data['journalText'] ?? 'No text';
          final before =
              data.containsKey('beforeStressLevel') ? data['beforeStressLevel'] : -1;
          final after =
              data.containsKey('afterStressLevel') ? data['afterStressLevel'] : -1;
          final drawingData = data['drawingData'] as List<dynamic>?;
          final entryTitle = data['entryTitle'] ?? 'Untitled Entry';

          // Use the new helper here
          final beforeData = getStressEmojiAndLabel(before);
          final afterData = getStressEmojiAndLabel(after);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entry Title
                  Text(
                    entryTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Drawing Section
                  if (drawingData != null) ...[
                    Text(
                      "Your Drawing",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor),
                    ),
                    const SizedBox(height: 10),
                    buildPixelArtDrawing(drawingData),
                    const SizedBox(height: 20),
                  ],
                  
                  // Journal Section
                  Text(
                    "Journal",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Text(
                      journal,
                      style: const TextStyle(fontSize: 16, color: textColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Stress Levels Section
                  Text(
                    "Stress Level (Before)",
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: getStressColor(before),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          beforeData['emoji']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          beforeData['label']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Stress Level (After)",
                    style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: getStressColor(after),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          afterData['emoji']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          afterData['label']!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}