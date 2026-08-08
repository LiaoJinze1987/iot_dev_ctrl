import 'package:flutter/material.dart';
import 'beans.dart';
import 'app_data.dart';
import 'http_api.dart';

class DevControl extends StatefulWidget {

  const DevControl({super.key});

  @override
  State<DevControl> createState() => _DevControl();
}

class _DevControl extends State<DevControl> {

  late Device device;
  String hint = "模拟空调设备测试";

  @override
  void initState() {
    super.initState();
    device = AppData.instance.currentDevice!;
  }

  @override
  void dispose() {
    AppData.instance.currentDevice = null;
    super.dispose();
  }

  Future<void> sendCommand() async {
    setState(() {
      hint = "发送模拟命令中";
    });
    try {
      final deviceId = device.deviceId;
      String command = "01_26";
      final result = await HttpApi.deviceCommand(deviceId, command);
      setState(() {
        if(result["code"] == 200) {
          final cmdResult = result["result"];
          hint = cmdResult["message"];
        } else {
          hint = "服务器异常";
        }
      });
    } catch(e) {
      setState(() {
        hint = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("设备命令操作"),
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              hint,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendCommand,
              child: const Text("发送模拟测试命令"),
            )
          ],
        ),
      ),
    );
  }
}