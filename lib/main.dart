// Complejo Intercultural y Deportivo Mushuc Runa
// Storefront app publicada en App Store / Play Store con bundle
// `pixel.mushucpark.com`. La UI es la del manual de marca; los datos
// se consumen del backend NestJS de `park-demo-admin/api`.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/access_flow.dart';
import 'design/brand_theme.dart';
import 'shell/root_shell.dart';

// Re-exports para no romper imports públicos previos (tests, etc.).
export 'shell/fair_location.dart' show FairLocation, MapExperienceConfig;
export 'shell/root_shell.dart' show RootShell;
export 'screens/home_screen.dart' show HomeScreen;
export 'screens/map_screen.dart' show MapScreen;
export 'screens/packages_screen.dart' show PackagesScreen;
export 'screens/food_screen.dart' show FoodScreen;
export 'screens/restaurant_screen.dart' show RestaurantScreen;
export 'screens/schedule_screen.dart'
    show ScheduleScreen, EventDetailSheet, showEventDetailSheet;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MushucRunaApp());
}

class MushucRunaApp extends StatelessWidget {
  final Widget Function(bool active)? mapScreenBuilder;

  const MushucRunaApp({super.key, this.mapScreenBuilder});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Complejo Mushuc Runa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AccessGate(
        appBuilder: (session, onSignOut, onDeleteLocalAccount) => RootShell(
          session: session,
          onSignOut: onSignOut,
          onDeleteLocalAccount: onDeleteLocalAccount,
          mapScreenBuilder: mapScreenBuilder,
        ),
      ),
    );
  }
}
