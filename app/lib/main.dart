import 'package:flutter/material.dart';
import 'routes.dart';
import 'config.dart';

void main() async {
  //确保Flutter的运行环境已经初始化完成，然后你才能在runApp()之前调用Flutter提供的异步功能
  WidgetsFlutterBinding.ensureInitialized();
  await Config.loadJson();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ctrl App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}


