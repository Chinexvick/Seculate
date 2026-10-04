import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Poppins';

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.white,
        ),
        splashFactory: InkRipple.splashFactory,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      );
}

class AppText {
  AppText._();

  static const TextStyle splashTitle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 37,
    color: AppColors.primary,
  );

  static const TextStyle splashTagline = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontStyle: FontStyle.italic,
    fontSize: 14,
    color: AppColors.primary,
  );

  static const TextStyle h5 = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 26,
    height: 35 / 26,
    color: AppColors.black,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    color: AppColors.neutral200,
  );

  /// Title 1 - input text (15px).
  static const TextStyle title1 = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    color: AppColors.black,
  );

  static const TextStyle errorCaption = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w400,
    fontSize: 10,
    color: AppColors.alert,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 24 / 16,
    color: AppColors.white,
  );
}
