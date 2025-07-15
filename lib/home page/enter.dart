import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';

class EnterPage extends StatefulWidget {
  const EnterPage({super.key});

  @override
  State<EnterPage> createState() => _EnterPageState();
}

class _EnterPageState extends State<EnterPage> {
  static const Color backgroundColor = Color(0xFFF7F7F7); // Soft light grey
  static const Color primaryColor = Color(0xFF8E97FD);    // Calming purple
  static const Color accentColor = Color(0xFFFFC1CC);     // Soft pink
  static const Color textColor = Color(0xFF333333);       // Neutral text

  String? currentUsername;
  List<String> savedUsernames = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved usernames and current user
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      currentUsername = prefs.getString('current_username');
      savedUsernames = prefs.getStringList('saved_usernames') ?? [];
    });
  }

  // Save current user
  Future<void> _saveCurrentUser(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_username', username);
    
    // Add to saved usernames if not already there
    if (!savedUsernames.contains(username)) {
      savedUsernames.add(username);
      await prefs.setStringList('saved_usernames', savedUsernames);
    }
    
    setState(() {
      currentUsername = username;
    });
  }

  // Show user selection dialog
  void _showUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show saved usernames
            if (savedUsernames.isNotEmpty) ...[
              const Text("Existing Users:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...savedUsernames.map((username) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(username),
                trailing: currentUsername == username 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _saveCurrentUser(username);
                  Navigator.pop(context);
                },
              )),
              const Divider(),
            ],
            
            // Add new user button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showAddUserDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text("Add New User"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  // Show add new user dialog
  void _showAddUserDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New User"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Enter your name",
            hintText: "e.g. John, Sarah, etc.",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final username = controller.text.trim();
              if (username.isNotEmpty) {
                _saveCurrentUser(username);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Clickable user icon at top right
          Positioned(
            top: 40,
            right: 20,
            child: GestureDetector(
              onTap: _showUserDialog,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: accentColor.withAlpha((255 * 0.2).toInt()),
                child: currentUsername != null
                    ? Text(
                        currentUsername![0].toUpperCase(),
                        style: const TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(Icons.person, color: textColor),
              ),
            ),
          ),
          
          // Show current user name below the icon
          if (currentUsername != null)
            Positioned(
              top: 70,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha((255 * 0.1).toInt()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentUsername!,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          
          // Centered content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🖌️',
                  style: TextStyle(fontSize: 50),
                ),
                const SizedBox(height: 20),
                Text(
                  'Digital Drawing Journal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                
                // Welcome message if user is selected
                if (currentUsername != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Welcome, $currentUsername!',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor.withAlpha((255 * 0.7).toInt()),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 60),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    // Check if user is selected
                    if (currentUsername == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a user first by tapping the user icon!'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                  child: const Text(
                    'Start Journaling',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}