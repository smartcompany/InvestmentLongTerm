import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/colors.dart';
import '../screens/home_screen.dart';
import '../screens/retire_simulator.dart';
import '../screens/settings_screen.dart';

class TabNavigation extends StatelessWidget {
  final bool isHomeScreen;

  const TabNavigation({super.key, required this.isHomeScreen});

  void _navigateToHomeScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionDuration: Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToRetireSimulatorScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RetireSimulatorScreen(),
        transitionDuration: Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToSettingsScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.navyMedium,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate700),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TabButton(
                      label: l10n.pastAssetSimulation,
                      isSelected: isHomeScreen,
                      onPressed: () {
                        if (!isHomeScreen) {
                          _navigateToHomeScreen(context);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: _TabButton(
                      label: l10n.retirementSimulation,
                      isSelected: !isHomeScreen,
                      onPressed: () {
                        if (isHomeScreen) {
                          _navigateToRetireSimulatorScreen(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        /*
        SizedBox(width: 12),
        IconButton(
          icon: Icon(Icons.settings, color: Colors.white, size: 24),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 24, minHeight: 24),
          onPressed: () => _navigateToSettingsScreen(context),
        ),
        */
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.navyDark : AppColors.slate300,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
