import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Audio alert service for drowsiness detection
/// Matches Python implementation using pygame for audio playback
class AudioAlertService {
  static AudioAlertService? _instance;
  static AudioAlertService get instance {
    _instance ??= AudioAlertService._();
    return _instance!;
  }
  
  AudioAlertService._() {
    // Private constructor for singleton pattern
  }
  
  AudioPlayer? _alertPlayer;
  bool _isPlaying = false;
  
  /// Initialize audio service
  Future<void> initialize() async {
    try {
      debugPrint('AudioAlertService: Initializing audio player');
      _alertPlayer = AudioPlayer();
      await _alertPlayer!.setSource(AssetSource('assets/audio/wakeup.mp3'));
      debugPrint('AudioAlertService: Audio player initialized successfully');
    } catch (e) {
      debugPrint('AudioAlertService: Failed to initialize audio player: $e');
    }
  }
  
  /// Play alert sound once
  Future<void> playAlert() async {
    if (_alertPlayer == null || _isPlaying) {
      debugPrint('AudioAlertService: Audio player not ready or already playing');
      return;
    }
    
    try {
      _isPlaying = true;
      await _alertPlayer!.play(AssetSource('assets/audio/wakeup.mp3'));
      debugPrint('AudioAlertService: Alert sound playing');
      
      // Auto-stop after playing once (matching Python behavior)
      _alertPlayer!.onPlayerComplete.listen((_) {
        _isPlaying = false;
        debugPrint('AudioAlertService: Alert sound finished playing');
      });
    } catch (e) {
      debugPrint('AudioAlertService: Error playing alert: $e');
      _isPlaying = false;
    }
  }
  
  /// Play alert sound continuously (loop)
  Future<void> playAlertLoop() async {
    if (_alertPlayer == null) {
      debugPrint('AudioAlertService: Audio player not ready');
      return;
    }
    
    try {
      _isPlaying = true;
      await _alertPlayer!.setReleaseMode(ReleaseMode.loop);
      await _alertPlayer!.play(AssetSource('assets/audio/wakeup.mp3'));
      debugPrint('AudioAlertService: Alert sound playing in loop');
    } catch (e) {
      debugPrint('AudioAlertService: Error playing alert loop: $e');
      _isPlaying = false;
    }
  }
  
  /// Stop alert sound
  Future<void> stopAlert() async {
    if (_alertPlayer == null) {
      debugPrint('AudioAlertService: Audio player not ready');
      return;
    }
    
    try {
      _isPlaying = false;
      await _alertPlayer!.stop();
      debugPrint('AudioAlertService: Alert sound stopped');
    } catch (e) {
      debugPrint('AudioAlertService: Error stopping alert: $e');
    }
  }
  
  /// Check if audio is currently playing
  bool get isPlaying => _isPlaying;
  
  /// Dispose audio service
  void dispose() {
    _alertPlayer?.dispose();
    _alertPlayer = null;
    _isPlaying = false;
    debugPrint('AudioAlertService: Audio service disposed');
  }
}