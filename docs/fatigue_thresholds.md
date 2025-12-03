# Fatigue Detection Thresholds Configuration

This document outlines all the fatigue detection thresholds that are now configurable in `lib/config/app_config.dart`.

## Basic Detection Thresholds

### Eye Aspect Ratio (EAR)
- **earThreshold**: `0.25` - Below this indicates eye closure
- **earConsecutiveFrames**: `2` - Consecutive frames needed to confirm eye closure
- **earConfidenceThreshold**: `0.8` (80%) - Multiplier for confidence calculation
- **earFallbackThreshold**: `0.05` - Adjustment for fallback detection

### Mouth Aspect Ratio (MAR)
- **marThreshold**: `0.65` - Above this indicates mouth opening/yawning
- **marConsecutiveFrames**: `2` - Consecutive frames needed to confirm yawn
- **marConfidenceThreshold**: `1.5` (150%) - Multiplier for confidence calculation

### Head Tilt
- **headTiltThresholdDegrees**: `8` - Degrees beyond which indicates head drooping (reduced from 15 based on real-world testing)
- **headTiltConfidenceThreshold**: `1.5` (150%) - Multiplier for confidence calculation
- **shoulderTiltThreshold**: `0.6` (60%) - Lower threshold for Z-axis (ear to shoulder tilts) for better detection
- **severeShoulderTiltThreshold**: `0.8` (80%) - Lower threshold for Z-axis severe detection

### Timing
- **blinkResetTimeSeconds**: `60` - Seconds before blink/yawn counters reset

## Fatigue Scoring Weights

- **blinkWeight**: `0.4` (40%) - Weight of blink count in fatigue score
- **yawnWeight**: `0.3` (30%) - Weight of yawn count in fatigue score
- **headTiltWeight**: `0.3` (30%) - Weight of head tilt in fatigue score

## Scoring Thresholds

- **maxBlinkCountForScoring**: `25` - Maximum blinks for scoring normalization
- **maxYawnCountForScoring**: `3` - Maximum yawns for scoring normalization
- **drowsinessScoreThreshold**: `40.0` - Score threshold for fatigue detection

## Multi-Indicator Fatigue Detection

These thresholds are used when multiple indicators suggest fatigue before upgrading to moderate level:

- **multiIndicatorEarThreshold**: `0.8` (80%) - EAR multiplier for multi-indicator detection
- **multiIndicatorMarThreshold**: `1.5` (150%) - MAR multiplier for multi-indicator detection
- **multiIndicatorHeadTiltThreshold**: `1.5` (150%) - Head tilt multiplier for multi-indicator detection
- **multiIndicatorBlinkThreshold**: `25` - Blink count threshold for multi-indicator detection
- **multiIndicatorYawnThreshold**: `8` - Yawn count threshold for multi-indicator detection
- **multiIndicatorMinIndicators**: `2` - Minimum number of indicators required

## Severe Fatigue Detection

- **severeBlinkThreshold**: `30` - Blink count threshold for severe fatigue
- **severeYawnThreshold**: `8` - Yawn count threshold for severe fatigue
- **severeHeadTiltThreshold**: `1.2` (120%) - Head tilt multiplier for severe fatigue

## ML Kit Integration

- **mlKitEyeOpenProbabilityThreshold**: `0.3` - Consider eyes closed if < 30% open probability

## Sustained Mouth Opening

- **sustainedMouthOpeningMultiplier**: `2` - Multiplier for sustained mouth opening detection

## Fatigue Level Determination Logic

### Alert Level
- Default state when no fatigue indicators are detected

### Mild Fatigue Level
- Triggered by EAR < 0.25 for 2 consecutive frames
- OR eyes closed with ML Kit probability < 30%

### Moderate Fatigue Level
- Triggered by ANY of:
  - MAR > 0.65 for 4 consecutive frames (sustained yawning)
  - At least 2 of: EAR < 0.20, MAR > 0.98, head tilt > 12°, blinks > 25, yawns > 8
  - ENHANCED: Z-axis (ear to shoulder) tilt > 4.8° (lower threshold for better shoulder tilt detection)

### Severe Fatigue Level
- Triggered by:
  - (Yawns > 8 OR blinks > 30) AND head tilt > 18°
  - ENHANCED: (Yawns > 8 OR blinks > 30) AND Z-axis (ear to shoulder) tilt > 6.4°

## Implementation Notes

- All thresholds are now centralized in `AppConfig` class
- No hardcoded values remain in `FatigueDetector`
- Core algorithm behavior is preserved
- All values are easily tunable for different conditions
- State smoothing uses 5-frame history to prevent rapid changes
- Spray alerts are triggered at moderate and severe levels