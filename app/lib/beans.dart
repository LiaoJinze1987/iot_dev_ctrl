class Device {
  final String deviceId;
  final String deviceName;

  Device({
    required this.deviceId,
    required this.deviceName,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json["device_id"],
      deviceName: json["device_name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "device_id": deviceId,
      "device_name": deviceName,
    };
  }
}