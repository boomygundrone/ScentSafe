# ScentSafe Project Architecture Rules

## Project Structure
```
scentsafe/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── models/
│   │   └── detection_result.dart # Detection result models
│   └── services/
│       ├── face_detector.dart     # Face detection service
│       └── fatigue_detector.dart # Fatigue detection algorithm
├── macos/                     # macOS platform files
├── web/                        # Web platform files
└── pubspec.yaml               # Dependencies and metadata
```

## Code Organization Rules

### 1. Service Layer
- All business logic goes in `lib/services/`
- Services should be stateless and reusable
- Each service should have clear initialization, processing, and disposal methods
- Use dependency injection pattern for services

### 2. Model Layer
- All data models go in `lib/models/`
- Models should be immutable where possible
- Include serialization methods (toJson/fromJson)
- Use proper enum types for fixed values

### 3. UI Layer
- Main UI in `lib/main.dart` for simple projects
- Use StatefulWidget for stateful components
- Keep UI logic separate from business logic
- Use Material Design components

## Flutter Specific Rules

### Dependencies
- Add all dependencies to `pubspec.yaml`
- Use latest stable versions
- Group related dependencies together
- Keep dev dependencies separate

### Platform Support
- Support web and macOS platforms
- Handle platform-specific APIs gracefully
- Use conditional imports when needed
- Test on all supported platforms

### State Management
- Use StatefulWidget for local state
- Keep state minimal and focused
- Dispose resources properly
- Use setState() only for UI updates

## ML Kit Integration Rules

### Face Detection
- Initialize detectors in async methods
- Handle no-face scenarios gracefully
- Process largest face when multiple detected
- Extract relevant landmarks for fatigue analysis

### Fatigue Detection
- Use Eye Aspect Ratio (EAR) for eye closure
- Use Mouth Aspect Ratio (MAR) for yawning
- Track consecutive frames for accuracy
- Implement confidence scoring

## Performance Rules

### Memory Management
- Dispose controllers and detectors
- Clear image caches
- Use efficient data structures
- Monitor memory usage

### Processing
- Use background threads for heavy processing
- Implement debouncing for rapid inputs
- Cache results when appropriate
- Optimize image processing pipeline

## Security Rules

### Data Privacy
- Process images locally only
- No network transmission of face data
- Clear temporary files
- Use secure storage for settings

### Permissions
- Request camera permissions properly
- Handle permission denials gracefully
- Provide clear permission explanations
- Check permissions before usage

## Testing Rules

### Unit Tests
- Test all service methods
- Mock external dependencies
- Test edge cases and error conditions
- Maintain >80% code coverage

### Integration Tests
- Test full detection pipeline
- Test with different lighting conditions
- Test with various face orientations
- Test performance under load

## Documentation Rules

### Code Comments
- Document public APIs
- Explain complex algorithms
- Add usage examples
- Maintain comment accuracy

### README
- Include setup instructions
- Document API usage
- Provide troubleshooting guide
- Add contribution guidelines