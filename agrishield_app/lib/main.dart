import 'package:agrishield_app/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'config/app_config.dart';
import 'controllers/language_controller.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init();

  // Initialize LanguageController
  Get.put(LanguageController(), permanent: true);

  // Auto-discover and connect to local backend (USB adb-reverse / Wi-Fi)
  try {
    await AppConfig.autoDiscoverBackend().timeout(const Duration(seconds: 4));
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final langController = Get.find<LanguageController>();

    return Obx(() => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AgriShield AI',
          theme: ThemeData(primarySwatch: Colors.green),
          locale: langController.currentLocale.value,
          fallbackLocale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
        ));
  }
}