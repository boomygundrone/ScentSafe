import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/bluetooth_device.dart';
import '../services/bluetooth_service.dart';

part 'bluetooth_state.dart';

class BluetoothCubit extends Cubit<BluetoothState> {
  final BluetoothService _bluetoothService;
  StreamSubscription<List<BluetoothDevice>>? _deviceSubscription;

  BluetoothCubit(this._bluetoothService) : super(BluetoothInitial()) {
    _initialize();
  }

  void _initialize() {
    // CRITICAL FIX: Store subscription for proper cleanup
    _deviceSubscription = _bluetoothService.deviceStream.listen(
      (devices) {
        emit(BluetoothDevicesFound(devices));
      },
      onError: (error) {
        emit(BluetoothError(error.toString()));
      },
    );
  }

  Future<void> startScan() async {
    emit(BluetoothScanning());
    try {
      await _bluetoothService.startScan();
    } catch (e) {
      emit(BluetoothError(e.toString()));
    }
  }

  Future<void> stopScan() async {
    try {
      await _bluetoothService.stopScan();
      emit(BluetoothScanStopped());
    } catch (e) {
      emit(BluetoothError(e.toString()));
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    emit(BluetoothConnecting(device));
    try {
      await _bluetoothService.connectToDevice(device);
      emit(BluetoothConnected(device));
    } catch (e) {
      emit(BluetoothError(e.toString()));
    }
  }

  Future<void> disconnectDevice() async {
    try {
      await _bluetoothService.disconnectDevice();
      emit(BluetoothDisconnected());
    } catch (e) {
      emit(BluetoothError(e.toString()));
    }
  }

  Future<void> triggerSpray() async {
      try {
        await _bluetoothService.triggerSpray();
        emit(BluetoothSprayTriggered());
      } catch (e) {
        emit(BluetoothError(e.toString()));
      }
    }
  
    @override
    Future<void> close() {
      // CRITICAL FIX: Cancel stream subscription to prevent memory leaks
      _deviceSubscription?.cancel();
      return super.close();
    }
  }