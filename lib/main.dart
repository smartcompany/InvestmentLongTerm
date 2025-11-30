import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state_provider.dart';
import 'screens/home_screen.dart';
import 'utils/colors.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => AppStateProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '장기투자 시뮬레이터',
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
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
