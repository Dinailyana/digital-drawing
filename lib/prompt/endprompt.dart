import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndPromptPage extends StatefulWidget {
  const EndPromptPage({super.key});

  @override
  State<EndPromptPage> createState() => _EndPromptPageState();
}

class _EndPromptPageState extends State<EndPromptPage> {
  int selectedLevel = -1;

  final List<String> stressEmojis = [
    "😌", "🙂", "😐", "😟", "😣"
  ];

  late String entryDocId;
  int? beforeStressLevel;
  bool isLoading = false;
  String? currentUsername; // Add this to store current user

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Load current user when page initializes
  }

  // Load current user from SharedPreferences
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString('current_username');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! Map<String, dynamic>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid navigation data.")),
        );
        Navigator.pop(context);
      });
      return;
    }

    entryDocId = args['docId'];
    beforeStressLevel = args['beforeStressLevel'];
  }

  Future<void> submitLevel() async {
    if (selectedLevel == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("How did you feel now after drawing?")),
      );
      return;
    }

    // Check if user is selected
    if (currentUsername == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a user first!")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Update the document with both afterStressLevel AND userId
      await FirebaseFirestore.instance
          .collection('journalEntries')
          .doc(entryDocId)
          .update({
        'afterStressLevel': selectedLevel,
        'userId': currentUsername, // Add user ID to the entry
        'updatedAt': FieldValue.serverTimestamp(), // Optional: track when updated
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you! Entry saved.")),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save stress level: $e")),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void goToCancelPage() {
    Navigator.pushNamed(context, '/submitCancel', arguments: {
      'docId': entryDocId,
      'beforeStressLevel': beforeStressLevel,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: goToCancelPage),
        title: const Text("End Prompt"),
        // Optional: Show current user in app bar
        actions: [
          if (currentUsername != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Text(
                  currentUsername!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Text(
              "How do you feel now?",
              style: TextStyle(fontSize: 24),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(stressEmojis.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedLevel = index;
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor:
                        selectedLevel == index ? Colors.blue : Colors.grey[300],
                    radius: 30,
                    child: Text(
                      stressEmojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : submitLevel,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}