import 'dart:convert';
import 'beans.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class HttpApi {

  static Future<Map<String, dynamic>> checkApp() async {
    final response = await http.post(
      Uri.parse(Config.checkUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "app_id": Config.appId,
        "app_name": Config.appName
      })
    );
    return jsonDecode(response.body);
  }

  static Future<List<Device>> deviceList() async {
    final response = await http.get(Uri.parse(Config.devList));
    final json = jsonDecode(response.body);
    if (json["code"] != 200) {
      throw Exception("server error");
    }
    return (json["device"] as List)
        .map((e) => Device.fromJson(e))
        .toList();
  }

  static Future<Map<String, dynamic>> deviceCommand(String deviceId,
      String command) async {
    final response = await http.post(
      Uri.parse(Config.devCommand),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "device_id": deviceId,
        "command": command
      })
    );
    return jsonDecode(response.body);
  }

}