class BluetoothDevice {
  final String id;
  final String name;
  final bool isConnected;
  final int rssi;

  BluetoothDevice({
    required this.id,
    required this.name,
    required this.isConnected,
    required this.rssi,
  });

  factory BluetoothDevice.fromJson(Map<String, dynamic> json) {
    return BluetoothDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      isConnected: json['isConnected'] as bool,
      rssi: json['rssi'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isConnected': isConnected,
      'rssi': rssi,
    };
  }

  bool get isAromaDiffuser => name.toLowerCase().contains('aroma') ||
                              name.toLowerCase().contains('diffuser') ||
                              name.toLowerCase().contains('scent');
}