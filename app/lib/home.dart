import 'beans.dart';
import 'package:flutter/material.dart';
import 'app_data.dart';
import 'http_api.dart';
import 'routes.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> checkApp() async {
    try {
      final result = await HttpApi.checkApp();
      setState(() {
        if(result["code"] == 200){
          AppData.instance.checkState = "验证成功";
        }else{
          AppData.instance.checkState = "验证失败";
        }
      });
    } catch(e) {
      setState(() {
        AppData.instance.checkState = "验证失败";
      });
    }
  }

  Future<void> loadDevList() async {
    try {
      final list = await HttpApi.deviceList();
      setState(() {
        AppData.instance.deviceList = list;
      });
    } catch(e) {
      print(e.toString());
    }
  }

  Future<void> refresh() async {
    await checkApp();
    await loadDevList();
  }

  void tapClick(Device device) {
    AppData.instance.currentDevice = device;
    Navigator.pushNamed(context, AppRoutes.control);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppData.instance.checkState),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        itemCount: AppData.instance.deviceList.length,
        itemBuilder: (context, index) {
          final device = AppData.instance.deviceList[index];
          return ListTile(
            title: Text("${device.deviceId}:${device.deviceName}"),
            onTap: () => tapClick(device),
          );
        },
      ),
    );
  }
}