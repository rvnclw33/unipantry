import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/app.dart';
import 'package:unipantry/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (Works on Web if firebase_options.dart is correct)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications (Skip on Web)
  if (!kIsWeb) {
    try {
      await NotificationService().init();
    } catch (e) {
      print("Notification Init Failed: $e");
    }
  }

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}