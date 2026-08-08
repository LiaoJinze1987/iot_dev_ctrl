import 'package:flutter/cupertino.dart';
import 'splash.dart';
import 'home.dart';
import 'control.dart';

class AppRoutes {
  static const String splash = "/";
  static const String home = "/home";
  static const String control = "/control";

  static final Map<String, WidgetBuilder> routes = {
    splash:(_) => const Splash(),
    home:(_) => const Home(),
    control: (_) => const DevControl(),
  };
}
