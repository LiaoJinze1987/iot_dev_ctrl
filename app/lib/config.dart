import 'dart:convert';
import 'package:flutter/services.dart';

class Config {

  static const String baseUrl = "http://192.168.1.13:8000";

  static String get checkUrl => "$baseUrl/appCheck";
  static String get devList => "$baseUrl/deviceList";
  static String get devCommand => "$baseUrl/deviceCommand";

  static late String appId;
  static late String appName;

  static Future<void> loadJson() async {
    String sJson = await rootBundle.loadString("assets/config.json");
    Map<String, dynamic> json = jsonDecode(sJson);
    appId = json["app_id"];
    appName = json["app_name"];
  }

}