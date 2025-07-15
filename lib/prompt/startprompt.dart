import 'package:flutter/material.dart';

class StartPromptPage extends StatefulWidget {
  const StartPromptPage({super.key});

  @override
  State<StartPromptPage> createState() => _StartPromptPageState();
}

class _StartPromptPageState extends State<StartPromptPage> {
  int selectedLevel = -1;

  final List<String> stressEmojis = ["😌", "🙂", "😐", "😟", "😣"];

  static const Color backgroundColor = Color(0xFFF7F7F7);
  static const Color primaryColor = Color(0xFF8E97FD);

  void submitLevel() {
    if (selectedLevel == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your stress level.")),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/drawing',
      arguments: {
        'beforeStressLevel': selectedLevel,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              const Text(
                "How stressed are you?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(stressEmojis.length, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedLevel = index),
                    child: CircleAvatar(
                      backgroundColor: selectedLevel == index ? primaryColor : Colors.grey[300],
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
                onPressed: submitLevel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text("Submit", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
