import 'package:acqa/firebase_options.dart';
import 'package:acqa/home.dart';
import 'package:acqa/login.dart';
import 'package:acqa/register.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'calendario.dart';
import 'lista.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACQA DPDM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => const HomePage(),
        '/lista': (context) => const ListaTarefasPage(),
        '/calendario': (context) => const CalendarPage(),
      },
    );
  }
}
