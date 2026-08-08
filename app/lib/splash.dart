import 'package:flutter/material.dart';
import 'http_api.dart';
import 'app_data.dart';
import 'routes.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _Splash();
}

class _Splash extends State<Splash> {

  @override
  void initState() {
    super.initState();
    checkApp();
  }

  //服务器判断唯一性
  Future<void> checkApp() async {
    if(!mounted) return;
    setState(() {
      AppData.instance.checkState = "检查唯一性";
    });
    try {
      final result = await HttpApi.checkApp();
      if(result["code"] == 200){
        AppData.instance.checkState = "验证成功";
      }else{
        AppData.instance.checkState = "验证失败";
      }
    } catch(e) {
      AppData.instance.checkState = "验证失败";
    }
    if(!mounted)return;
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          AppData.instance.checkState,
          style: const TextStyle(
            fontSize: 14
          ),
        ),
      ),
    );
  }
}