import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/routes.dart';
import 'core/supabase/supabase_config.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const SeculateApp());
}

class SeculateApp extends StatelessWidget {
  const SeculateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seculate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: Routes.splash,
      onGenerateRoute: Routes.generate,
    );
  }
}
