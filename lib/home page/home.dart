import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../prompt/startprompt.dart';
import '../drawings/eachdrawing.dart'; 
import '../drawings/pastdrawings.dart'; 
import '../insight/insight.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String greeting = '';
  String? currentUsername; // Add this to store current user

  final Color backgroundColor = const Color(0xFFF7F7F7);
  final Color primaryColor = const Color(0xFF71C9CE);
  final Color accentColor = const Color(0xFFFFA8A3);
  final Color textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadCurrentUser(); // Load current user
  }

  // Load current user from SharedPreferences
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString('current_username');
    });
  }

  void _updateGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 18) {
      greeting = 'Good Evening';
    } else {
      greeting = 'Good Night';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Wait for currentUsername to load
    if (currentUsername == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          title: Text(
            greeting,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          greeting,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // SECURITY FIX: Filter by current user's ID
        stream: FirebaseFirestore.instance
            .collection('journalEntries')
            .where('userId', isEqualTo: currentUsername) // Only show current user's entries
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading entries'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data!.docs;

          // Sort entries by timestamp in descending order (newest first)
          entries.sort((a, b) {
            final aTimestamp = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            final bTimestamp = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
            
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp); // Descending order
          });

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No journal entries yet.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to create your first entry!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              var entry = entries[index];
              var data = entry.data() as Map<String, dynamic>;
              
              // Additional security check (though the query should already filter)
              if (data['userId'] != currentUsername) {
                return const SizedBox.shrink(); // Don't show entries that don't belong to current user
              }
              
              var journalText = data['journalText'] ?? '';
              var entryTitle = data['entryTitle'] ?? 'Untitled Entry';
              var date = (data['timestamp'] as Timestamp?)?.toDate();
              var formattedDate = date != null
                  ? "${date.day}/${date.month}/${date.year}"
                  : 'Unknown Date';
              var entryId = entry.id; // Get the document ID

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    entryTitle, // Show entry title instead of generic "Journal Entry"
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: $formattedDate'),
                      const SizedBox(height: 5),
                      Text(
                        journalText.length > 100
                            ? '${journalText.substring(0, 100)}...'
                            : journalText,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EachDrawingPage(entryId: entryId), // Navigate with entryId
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: const Color(0xFFF1F1F1),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.bar_chart, color: accentColor),
                onPressed: () {
                  // Navigate to insights page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InsightsPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.brush, color: accentColor),
                onPressed: () {
                  // Navigate to past drawings page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PastDrawingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 4,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StartPromptPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}