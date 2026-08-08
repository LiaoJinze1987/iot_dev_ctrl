import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Device extends StatefulWidget {
  const Device({super.key});

  @override
  State<Device> createState() => _Device();
}

class _Device extends State<Device> {
  WebSocketChannel? channel;
  String deviceState = "未连接";
  String hint = "等待启动";
  final String deviceId = "AC001";
  final String deviceName = "模拟空调";
  final String url = "ws://192.168.1.13:8000/device/connect";

  @override
  void initState() {
    super.initState();
    connect();
  }

  void connect() {
    try {
      channel = WebSocketChannel.connect(Uri.parse(url));
      setState(() {
        deviceState = "连接正常";
        hint = "WebSocket连接成功";
      });
      channel!.stream.listen((message) {
        handMessage(message);
      }, onError: (e) {
        setState(() {
          deviceState = "连接异常";
          hint = e.toString();
        });
      }, onDone: () {
        setState(() {
          deviceState = "连接关闭";
          hint = "Server断开连接";
        });
      });
      sendOnline();
    } catch (e) {
      setState(() {
        deviceState = "连接失败";
        hint = e.toString();
      });
    }
  }

  //设备上线注册，协议:设备ID;设备名称;01;0x00
  void sendOnline() {
    channel!.sink.add("$deviceId;$deviceName;01;0x00");
    setState(() {
      hint = "发送设备上线";
    });
  }

  //处理Server消息
  void handMessage(String message) {
    final data = message.split(";");
    try {
      String commandType = data[2];
      String command = data[3];
      //Server发送心跳
      if (commandType == "02") {
        heartbeat();
      }
      //Server发送控制命令
      if (commandType == "03") {
        handleCommand(command);
      }
    } catch (e) {
      setState(() {
        hint = e.toString();
      });
    }
  }

  //回应心跳，协议:设备ID;_;02;0x01
  void heartbeat() {
    try {
      String msg = "$deviceId;_;02;0x01";
      channel!.sink.add(msg);
      setState(() {
        hint = "发送心跳回应完毕";
      });
    } catch (e) {
      setState(() {
        hint = e.toString();
      });
    }
  }

  //处理控制命令
  void handleCommand(String command) {
    setState(() {
      hint = "收到命令:$command";
    });
    //以app控制空调调整为26度为例，命令为：01_26
    try {
      final data = command.split("_");
      if (data[0] == "01") {
        if (data[1] == "26") {
          Future.delayed(const Duration(seconds: 2), () {
            channel!.sink.add("$deviceId;_;03;0x01");
            setState(() {
              hint = "命令执行完成，返回成功";
            });
          });
        }
      }
    } catch (e) {
      setState(() {
        hint = "命令执行出错";
      });
    }
  }

  @override
  void dispose() {
    channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("模拟设备"),
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              "设备状态:$deviceState",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              "提示:$hint",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
