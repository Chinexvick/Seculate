import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../data/auth_service.dart';
import '../../data/profile_service.dart';

/// Blocking step: Seculate is a local marketplace, so the app does not
/// continue until the phone's location is shared. The location is stored
/// server-side and used for "near you" results and distance checks.
class LocationGateScreen extends StatefulWidget {
  const LocationGateScreen({super.key});

  @override
  State<LocationGateScreen> createState() => _LocationGateScreenState();
}

class _LocationGateScreenState extends State<LocationGateScreen>
    with WidgetsBindingObserver {
  bool _loading = false;
  String? _error;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from system settings: try again automatically.
    if (state == AppLifecycleState.resumed && _blocked && !_loading) _allow();
  }

  Future<void> _allow() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ProfileService.instance.captureLocation();
    if (!mounted) return;
    if (err == null) {
      await AuthService.instance.setStep('verification');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(Routes.identityVerification);
      return;
    }
    final perm = await ProfileService.instance.locationPermission();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
      _blocked = perm.name == 'deniedForever';
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => SystemNavigator.pop(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                FadeSlideIn(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                        color: Color(0xFFEAF9EE), shape: BoxShape.circle),
                    child: const Icon(Icons.location_on_rounded,
                        size: 60, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 28),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 80),
                  child: Text('Find items near you',
                      textAlign: TextAlign.center, style: AppText.h5),
                ),
                const SizedBox(height: 10),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 120),
                  child: Text(
                      'Seculate connects you with people close by. We use your location to show nearby items, services and tasks, and to keep meet-ups local and safe.',
                      textAlign: TextAlign.center,
                      style: AppText.body),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 18),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13,
                          color: AppColors.alert)),
                ],
                const Spacer(flex: 4),
                AppButton(
                  label: _blocked ? 'Open settings' : 'Allow location',
                  loading: _loading,
                  onPressed: _blocked
                      ? () => ProfileService.instance.openLocationSettings()
                      : _allow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
