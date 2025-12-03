part of 'detection_cubit.dart';

abstract class DetectionState extends Equatable {
  const DetectionState();

  @override
  List<Object> get props => [];
}

class DetectionInitial extends DetectionState {}

class DetectionRunning extends DetectionState {}

class DetectionStopped extends DetectionState {}

class DetectionResultUpdated extends DetectionState {
  final DetectionResult result;

  const DetectionResultUpdated(this.result);

  @override
  List<Object> get props => [result];
}

class DrowsinessDetected extends DetectionState {
  final DetectionResult result;

  const DrowsinessDetected(this.result);

  @override
  List<Object> get props => [result];
}

class DetectionError extends DetectionState {
  final String message;

  const DetectionError(this.message);

  @override
  List<Object> get props => [message];
}