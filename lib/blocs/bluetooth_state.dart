part of 'bluetooth_cubit.dart';

abstract class BluetoothState extends Equatable {
  const BluetoothState();

  @override
  List<Object> get props => [];
}

class BluetoothInitial extends BluetoothState {}

class BluetoothScanning extends BluetoothState {}

class BluetoothScanStopped extends BluetoothState {}

class BluetoothDevicesFound extends BluetoothState {
  final List<BluetoothDevice> devices;

  const BluetoothDevicesFound(this.devices);

  @override
  List<Object> get props => [devices];
}

class BluetoothConnecting extends BluetoothState {
  final BluetoothDevice device;

  const BluetoothConnecting(this.device);

  @override
  List<Object> get props => [device];
}

class BluetoothConnected extends BluetoothState {
  final BluetoothDevice device;

  const BluetoothConnected(this.device);

  @override
  List<Object> get props => [device];
}

class BluetoothDisconnected extends BluetoothState {}

class BluetoothSprayTriggered extends BluetoothState {}

class BluetoothError extends BluetoothState {
  final String message;

  const BluetoothError(this.message);

  @override
  List<Object> get props => [message];
}