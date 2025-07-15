import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'home page/enter.dart'; // Welcome page
import 'home page/home.dart'; // home page
import 'prompt/startprompt.dart'; // Stress prompt page
import 'journalentry/drawing.dart'; // drawing
import 'cancel/entrycancel.dart';//entry cancel page
import 'prompt/endprompt.dart';//end prompt after drawing
import 'drawings/eachdrawing.dart';//insight
import 'cancel/submitcancel.dart';//cancel submit
import 'insight/insight.dart';//insight
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAvpxYHAdOTDtJsm4du9VwwjeTUeMRbccc",
        authDomain: "digital-drawing-17311.firebaseapp.com",
        projectId: "digital-drawing-17311",
        storageBucket: "digital-drawing-17311.firebasestorage.app",
        messagingSenderId: "597385221526",
        appId: "1:597385221526:web:584c6357da0693a55779b7",
        measurementId: "G-9BG05GTSEM",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Welcome App',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const EnterPage(),
        '/home': (context) => const HomePage(),
        '/startprompt': (context) => const StartPromptPage(),
        '/cancel': (context) => const CancelEntryPage(),
        '/endprompt': (context) => const EndPromptPage(),
        '/submitcancel': (context) => const SubmitCancelPage(),
        '/drawing': (context) => const EntryPage(),
        '/insight': (context) => const InsightsPage(),
        '/eachdrawing': (context) {
          final String entryId = ModalRoute.of(context)!.settings.arguments as String;
          return EachDrawingPage(entryId: entryId);
        },
      },
    );
  }
}