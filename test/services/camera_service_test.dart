import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:scentsafe/services/camera_service.dart';

void main() {
  group('CameraService', () {
    group('Singleton Pattern', () {
      test('singleton pattern works correctly', () {
        final service1 = CameraService.instance;
        final service2 = CameraService.instance;
        
        expect(identical(service1, service2), true);
      });
    });

    group('Service State', () {
      late CameraService cameraService;

      setUp(() {
        cameraService = CameraService.instance;
      });

      test('initial state is correct', () {
        expect(cameraService.isInitialized, false);
        expect(cameraService.controller, isNull);
        expect(cameraService.isDisposed, true);
      });

      test('disposed state is tracked correctly', () {
        cameraService.dispose();
        expect(cameraService.isDisposed, true);
      });
    });

    group('Camera Controller', () {
      test('disposeCamera handles cleanup gracefully', () async {
        final service = CameraService.instance;
        await service.disposeCamera();
        expect(service.controller, isNull);
      });

      test('multiple dispose calls are safe', () async {
        final service = CameraService.instance;
        await service.disposeCamera();
        await service.disposeCamera(); // Should not throw
        expect(service.controller, isNull);
      });
    });

    group('UI Components', () {
      test('buildPreview returns a widget even when not initialized', () {
        final service = CameraService.instance;
        final widget = service.buildPreview();
        expect(widget, isA<Container>());
      });

      test('buildPreview handles disposed state gracefully', () {
        final service = CameraService.instance;
        service.dispose();
        final widget = service.buildPreview();
        expect(widget, isA<Container>());
      });
    });

    group('State Management', () {
      test('cameraStateStream is available', () {
        final service = CameraService.instance;
        final stream = service.cameraStateStream;
        expect(stream, isA<Stream<CameraState>>());
      });
    });
  });

  group('CameraState', () {
    test('state types are correct', () {
      final discovered = CameraState.discovered();
      expect(discovered.type, CameraStateType.discovered);
      expect(discovered.errorMessage, isNull);

      final initialized = CameraState.initialized();
      expect(initialized.type, CameraStateType.initialized);
      expect(initialized.errorMessage, isNull);

      final disposed = CameraState.disposed();
      expect(disposed.type, CameraStateType.disposed);
      expect(disposed.errorMessage, isNull);

      final error = CameraState.error('Test error');
      expect(error.type, CameraStateType.error);
      expect(error.errorMessage, 'Test error');
    });

    test('equality and hashCode work correctly', () {
      final state1 = CameraState.discovered();
      final state2 = CameraState.discovered();
      final state3 = CameraState.error('Test');

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('toString provides meaningful output', () {
      expect(CameraState.discovered().toString(), 'CameraState.discovered');
      expect(CameraState.initialized().toString(), 'CameraState.initialized');
      expect(CameraState.disposed().toString(), 'CameraState.disposed');
      expect(CameraState.error('Test error').toString(), 'CameraState.error: Test error');
    });
  });
}