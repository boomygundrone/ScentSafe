# ScentSafe Coding Standards

## Dart/Flutter Standards

### 1. Naming Conventions

#### Files and Directories
- Use `snake_case` for file names: `face_detector.dart`
- Use `snake_case` for directory names: `services/`, `models/`
- Keep file names descriptive and concise

#### Classes and Types
- Use `PascalCase` for class names: `FaceDetectorService`
- Use `PascalCase` for enums: `DrowsinessLevel`
- Use descriptive names that indicate purpose

#### Variables and Methods
- Use `camelCase` for variables: `_cameraController`
- Use `camelCase` for methods: `initializeCamera()`
- Use `camelCase` for constants: `earThreshold`

#### Private Members
- Prefix private members with underscore: `_isInitialized`
- Keep private scope minimal
- Document public interface clearly

### 2. Code Structure

#### Class Organization
```dart
class ExampleService {
  // 1. Static constants
  static const double THRESHOLD = 0.5;
  
  // 2. Private properties
  final _privateProperty;
  
  // 3. Constructor
  ExampleService(this._privateProperty);
  
  // 4. Public methods
  Future<void> publicMethod() async {}
  
  // 5. Private methods
  Future<void> _privateMethod() async {}
  
  // 6. Disposal
  void dispose() {}
}
```

#### Method Organization
- Constructor first
- Public methods next
- Private methods after public
- Getters and setters at end
- Dispose method last

### 3. Documentation Standards

#### Class Documentation
```dart
/// Brief description of the class purpose.
/// 
/// More detailed explanation if needed.
/// Include usage example for complex classes.
class FaceDetectorService {
  // ...
}
```

#### Method Documentation
```dart
/// Brief description of what the method does.
/// 
/// Parameters:
/// - [paramName]: Description of parameter
/// 
/// Returns:
/// - Description of return value
/// 
/// Throws:
/// - [ExceptionType]: When and why it's thrown
Future<DetectionResult> detectFatigue(InputImage image) async {
  // ...
}
```

### 4. Error Handling

#### Exception Types
- Use specific exception types
- Include descriptive messages
- Handle expected exceptions gracefully
- Log errors for debugging

#### Error Handling Pattern
```dart
Future<Result> riskyOperation() async {
  try {
    final result = await operation();
    return Result.success(result);
  } on NetworkException catch (e) {
    print('Network error: $e');
    return Result.failure('Network unavailable');
  } catch (e) {
    print('Unexpected error: $e');
    return Result.failure('Operation failed');
  }
}
```

### 5. Async Programming

#### Future Usage
- Always use `async`/`await` for async operations
- Handle Future completion properly
- Use timeout for long operations
- Cancel operations when appropriate

#### Stream Usage
```dart
Stream<DetectionResult> detectionStream() async* {
  while (_isDetecting) {
    final result = await _detectFrame();
    yield result;
    await Future.delayed(Duration(milliseconds: 100));
  }
}
```

### 6. State Management

#### StatefulWidget Pattern
```dart
class _ExampleWidgetState extends State<ExampleWidget> {
  // 1. State variables
  bool _isLoading = false;
  DetectionResult? _lastResult;
  
  // 2. Lifecycle methods
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
  
  // 3. Build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(/* ... */);
  }
  
  // 4. Private methods
  void _initialize() {}
  void _cleanup() {}
}
```

### 7. UI/UX Standards

#### Widget Composition
- Prefer composition over inheritance
- Use small, reusable widgets
- Keep build methods clean
- Separate business logic from UI

#### Material Design
- Use Material components consistently
- Follow Material Design guidelines
- Maintain proper spacing and typography
- Ensure accessibility

#### Responsive Design
```dart
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth > 600) {
        return _buildTabletLayout();
      } else {
        return _buildPhoneLayout();
      }
    },
  );
}
```

### 8. Performance Standards

#### Memory Management
- Dispose controllers and streams
- Use const constructors where possible
- Avoid unnecessary widget rebuilds
- Profile memory usage

#### Image Processing
- Process images on background threads
- Use efficient image formats
- Cache processed results
- Limit image resolution when possible

### 9. Testing Standards

#### Unit Tests
```dart
void main() {
  group('FaceDetectorService', () {
    test('should initialize successfully', () async {
      final service = FaceDetectorService();
      await service.initialize();
      expect(service.isInitialized, isTrue);
    });
    
    test('should handle no face detected', () async {
      final result = await service.processImage(emptyImage);
      expect(result, isNull);
    });
  });
}
```

#### Widget Tests
```dart
void main() {
  testWidgets('should show loading indicator', (tester) async {
    await tester.pumpWidget(MyApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

### 10. Git Standards

#### Commit Messages
- Use present tense: "Add feature" not "Added feature"
- Keep first line under 50 characters
- Include detailed body when needed
- Reference issue numbers when applicable

#### Branch Naming
- Use `feature/description` for features
- Use `bugfix/description` for fixes
- Use `hotfix/description` for urgent fixes
- Use `refactor/description` for refactoring

## Security Standards

### Data Protection
- Never log sensitive data
- Process images locally only
- Clear temporary files
- Use secure storage for settings

### Input Validation
- Validate all inputs
- Sanitize user data
- Handle malformed inputs
- Use type safety

## Review Checklist

Before submitting code, verify:

- [ ] All public methods are documented
- [ ] Error handling is comprehensive
- [ ] Async operations are properly handled
- [ ] Memory is managed correctly
- [ ] UI follows Material Design
- [ ] Tests are written and passing
- [ ] Code follows naming conventions
- [ ] No hardcoded values (use constants)
- [ ] Security best practices are followed
- [ ] Performance is considered