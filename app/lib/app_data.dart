import 'beans.dart';

class AppData {

  AppData._internal();

  static AppData instance = AppData._internal();

  String checkState = "等待验证";

  List<Device> deviceList = [];

  //当前操作的设备
  Device? currentDevice;
}