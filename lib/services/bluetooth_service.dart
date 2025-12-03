import 'dart:async';
import '../models/bluetooth_device.dart' as model;

class BluetoothService {
  final StreamController<List<model.BluetoothDevice>> _deviceController =
      StreamController<List<model.BluetoothDevice>>.broadcast();

  Stream<List<model.BluetoothDevice>> get deviceStream => _deviceController.stream;

  model.BluetoothDevice? _connectedDevice;
  dynamic _sprayCharacteristic; // For demo purposes

  Future<void> startScan() async {
    try {
      // Mock Bluetooth scan for demo
      await Future.delayed(const Duration(seconds: 2)); // Simulate scan delay

      // Mock devices for demo
      final mockDevices = [
        model.BluetoothDevice(
          id: 'mock_aroma_001',
          name: 'Aroma Diffuser Pro',
          isConnected: false,
          rssi: -45,
        ),
        model.BluetoothDevice(
          id: 'mock_aroma_002',
          name: 'ScentSafe Sprayer',
          isConnected: false,
          rssi: -52,
        ),
      ];

      _deviceController.add(mockDevices);
    } catch (e) {
      // Bluetooth scan error: $e
      rethrow;
    }
  }

  Future<void> stopScan() async {
    try {
      // Mock stop scan for demo
      // Scan stopped
    } catch (e) {
      // Stop scan error: $e
    }
  }

  Future<void> connectToDevice(model.BluetoothDevice device) async {
    try {
      // Mock connection for demo
      await Future.delayed(const Duration(seconds: 1)); // Simulate connection delay

      _connectedDevice = device;
      _sprayCharacteristic = 'mock_characteristic'; // Mock characteristic

      // Connected to ${device.name}
    } catch (e) {
      // Connection error: $e
      rethrow;
    }
  }

  Future<void> disconnectDevice() async {
    try {
      if (_connectedDevice != null) {
        // Mock disconnect for demo
        await Future.delayed(const Duration(milliseconds: 500));
        _connectedDevice = null;
        _sprayCharacteristic = null;
        // Disconnected from device
      }
    } catch (e) {
      // Disconnect error: $e
      rethrow;
    }
  }

  Future<void> triggerSpray() async {
    try {
      if (_sprayCharacteristic != null && _connectedDevice != null) {
        // Mock spray command for demo
        await Future.delayed(const Duration(milliseconds: 200)); // Simulate command delay
        // Spray command sent to ${_connectedDevice!.name}
      } else {
        throw Exception('No connected device or spray characteristic found');
      }
    } catch (e) {
      // Spray trigger error: $e
      rethrow;
    }
  }

  bool get isConnected => _connectedDevice != null;

  model.BluetoothDevice? get connectedDevice => _connectedDevice;

  void dispose() {
    _deviceController.close();
    disconnectDevice();
  }
}