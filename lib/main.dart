import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'l10n/app_localizations.dart';
import 'providers/app_state_provider.dart';
import 'providers/retire_simulator_provider.dart';
import 'providers/currency_provider.dart';
import 'screens/main_tab_screen.dart';
import 'providers/my_assets_provider.dart';
import 'providers/growth_race_provider.dart';
import 'utils/colors.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for Liquid Glass effect
  // 상태바와 네비게이션 바를 투명하게 설정하여 배경이 전체 화면에 표시되도록 함
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize Firebase
  try {
    await Firebase.initializeApp();

    // Initialize Firebase Analytics
    FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

    // Set up Crashlytics only after Firebase is initialized
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    // If Firebase initialization fails, log but don't crash
    debugPrint('Firebase initialization error: $e');
  }

  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();

  // Initialize Kakao SDK
  KakaoSdk.init(nativeAppKey: '30272b5f0271c22c1747949a87f1758d');

  // Initialize ad settings (앱 시작 시 한 번만 로드)
  AdService.shared.loadSettings();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => RetireSimulatorProvider()),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ChangeNotifierProvider(create: (_) => MyAssetsProvider()),
        ChangeNotifierProvider(create: (_) => GrowthRaceProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Capital',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ko'), // Korean
        Locale('zh'), // Chinese
        Locale('ja'), // Japanese
      ],
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.navyDark,
        primaryColor: AppColors.gold,
        colorScheme: ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.goldLight,
          surface: AppColors.navyMedium,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.navyDark,
          elevation: 0,
        ),
      ),
      home: MainTabScreen(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
