import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';  // Temporarily disabled
import 'package:provider/provider.dart';
import 'app/app_widget.dart';
import 'core/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  // await Firebase.initializeApp();  // Temporarily disabled
  
  runApp(const EventoApp());
}

class EventoApp extends StatelessWidget {
  const EventoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const AppWidget(),
    );
  }
}
