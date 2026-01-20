import Flutter
import ARKit

/// ARKit Face Tracker Plugin Registration
/// This file handles registration of ARKit Face Tracker with Flutter
public class ARKitFaceTrackerPlugin: NSObject, FlutterPlugin {
    
    private var channel: FlutterMethodChannel?
    private var session: ARSession?
    private var isRunning = false
    
    // Face tracking state
    private var lastBlinkTime: Date?
    private var blinkCount = 0
    private var eyesClosedStartTime: Date?
    private var eyesCurrentlyClosed = false
    
    // Configuration
    private let blinkThreshold: TimeInterval = 0.3 // Minimum duration for a valid blink
    private let eyesClosedWarningThreshold: TimeInterval = 3.0 // Warning after 3 seconds
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.scentsafe.drowsiness/arkit",
            binaryMessenger: registrar.messenger()
        )
        let instance = ARKitFaceTrackerPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "checkAvailability":
            checkAvailability(result: result)
        case "initialize":
            initialize(result: result)
        case "startDetection":
            startDetection(result: result)
        case "stopDetection":
            stopDetection(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// Check if ARKit face tracking is available
    private func checkAvailability(result: @escaping FlutterResult) {
        guard ARFaceTrackingConfiguration.isSupported else {
            result(false)
            return
        }
        result(true)
    }
    
    /// Initialize ARKit session
    private func initialize(result: @escaping FlutterResult) {
        // Create AR session
        session = ARSession()
        
        result(nil)
    }
    
    /// Start face detection
    private func startDetection(result: @escaping FlutterResult) {
        guard let session = session else {
            result(FlutterError(code: "SESSION_NOT_INITIALIZED",
                             message: "ARSession not initialized",
                             details: nil))
            return
        }
        
        // Create face tracking configuration
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        // Run configuration
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isRunning = true
        
        // Set up delegate
        session.delegate = self
        
        result(nil)
    }
    
    /// Stop face detection
    private func stopDetection(result: @escaping FlutterResult) {
        session?.pause()
        isRunning = false
        
        // Reset state
        lastBlinkTime = nil
        blinkCount = 0
        eyesClosedStartTime = nil
        eyesCurrentlyClosed = false
        
        result(nil)
    }
    
    /// Process face anchor data
    private func processFaceAnchor(_ anchor: ARFaceAnchor) {
        let geometry = anchor.geometry
        
        // Get eye state from anchor's blend shapes
        let leftEyeOpen = anchor.blendShapes[.eyeBlinkLeft]?.floatValue ?? 0.0 < 0.5
        let rightEyeOpen = anchor.blendShapes[.eyeBlinkRight]?.floatValue ?? 0.0 < 0.5
        
        // Track eye state changes
        updateEyeState(leftEyeOpen: leftEyeOpen, rightEyeOpen: rightEyeOpen)
        
        // Get blend shapes from anchor
        var blendShapes: [String: Double] = [:]
        for (shape, value) in anchor.blendShapes {
            blendShapes[shape.rawValue] = Double(value.floatValue)
        }
        
        // Get head orientation
        let headOrientation = extractHeadOrientation(from: anchor)
        
        // Prepare data for Flutter
        let data: [String: Any] = [
            "leftEyeOpen": leftEyeOpen,
            "rightEyeOpen": rightEyeOpen,
            "blendShapes": blendShapes,
            "headOrientation": headOrientation,
            "blinkCount": blinkCount,
            "eyesClosedDuration": eyesClosedStartTime != nil && eyesCurrentlyClosed ?
                Date().timeIntervalSince(eyesClosedStartTime!) : 0.0
        ]
        
        // Send to Flutter
        channel?.invokeMethod("onFaceDetected", arguments: data)
    }
    
    /// Update eye state and track blinks
    private func updateEyeState(leftEyeOpen: Bool, rightEyeOpen: Bool) {
        let eyesOpen = leftEyeOpen && rightEyeOpen
        
        if !eyesOpen && !eyesCurrentlyClosed {
            // Eyes just closed
            eyesCurrentlyClosed = true
            eyesClosedStartTime = Date()
        } else if eyesOpen && eyesCurrentlyClosed {
            // Eyes just opened - check if it was a blink
            eyesCurrentlyClosed = false
            
            if let closedTime = eyesClosedStartTime {
                let closedDuration = Date().timeIntervalSince(closedTime)
                
                // Count as blink if duration is within threshold
                if closedDuration >= blinkThreshold && closedDuration < eyesClosedWarningThreshold {
                    blinkCount += 1
                    lastBlinkTime = Date()
                    print("Blink detected (total: \(blinkCount))")
                }
            }
            
            eyesClosedStartTime = nil
        }
        
        // Check for prolonged eye closure
        if eyesCurrentlyClosed, let closedTime = eyesClosedStartTime {
            let closedDuration = Date().timeIntervalSince(closedTime)
            if closedDuration >= eyesClosedWarningThreshold {
                print("Warning: Eyes closed for \(closedDuration) seconds")
            }
        }
    }
    
    /// Extract head orientation from face anchor
    private func extractHeadOrientation(from anchor: ARFaceAnchor) -> [String: Double] {
        let transform = anchor.transform
        
        // Extract rotation matrix
        let columns = transform.columns
        
        // Calculate Euler angles (simplified)
        let pitch = atan2(columns.2.y, columns.2.z)
        let yaw = atan2(-columns.2.x, sqrt(columns.2.y * columns.2.y + columns.2.z * columns.2.z))
        let roll = atan2(columns.0.y, columns.0.x)
        
        return [
            "pitch": Double(pitch),
            "yaw": Double(yaw),
            "roll": Double(roll)
        ]
    }
}

// MARK: - ARSessionDelegate

extension ARKitFaceTrackerPlugin: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard isRunning else { return }
        
        for anchor in session.currentFrame?.anchors ?? [] {
            guard let faceAnchor = anchor as? ARFaceAnchor else { continue }
            processFaceAnchor(faceAnchor)
        }
    }
    
    /// Handle AR session errors
    public func session(_ session: ARSession, didFailWithError error: Error) {
        print("ARSession error: \(error.localizedDescription)")
        
        // Notify Flutter of error
        channel?.invokeMethod("onError", arguments: [
            "code": (error as NSError).code,
            "message": error.localizedDescription
        ])
    }
    
    /// Handle AR session interruptions
    public func sessionWasInterrupted(_ session: ARSession) {
        print("ARSession was interrupted")
        isRunning = false
    }
    
    /// Handle AR session interruption ended
    public func sessionInterruptionEnded(_ session: ARSession) {
        print("ARSession interruption ended")
        // Restart session if it was running
        if session != nil {
            startDetection { _ in }
        }
    }
}
