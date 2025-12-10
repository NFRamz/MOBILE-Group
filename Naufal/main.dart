import 'package:aisyiyah_smartlife/core/services/notification/notificationService.dart';
import 'package:aisyiyah_smartlife/core/theme/App_theme.dart';
import 'package:aisyiyah_smartlife/data/services/supabase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:aisyiyah_smartlife/routes/app_pages.dart';
import 'package:flutter/services.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Get.putAsync(() => SupabaseService().init());

  await Firebase.initializeApp();

  await Hive.initFlutter();
  await Hive.openBox('kegiatanBox');
  await Hive.openBox('userBox');
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  NotificationService().init();
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM TOKEN HP: $token");

  runApp(const AisyiyahSmartLifeApp());
}

class AisyiyahSmartLifeApp extends StatelessWidget {
  const AisyiyahSmartLifeApp({super.key});

  @override
  Widget build(BuildContext context) {


    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,

      theme: App_theme.lightTheme
    );
  }
}
