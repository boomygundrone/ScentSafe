# Flutter Path Rules for ScentSafe Project

## CRITICAL: Correct Flutter Installation Path

The Flutter SDK for the ScentSafe project is installed at:
```
/Users/kimberlychan/Development/scentsafe-app/flutter/
```

## INCORRECT PATH (DO NOT USE)
```
/Users/kimberlychan/Development/scentsafe-app/flutter/
```

## Rules for Flutter Commands

### 1. Always Use the Correct Path
When executing Flutter commands, ALWAYS use:
```bash
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter [command]
```

### 2. Recommended Commands
```bash
# Run in debug mode
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d web-server --debug

# Run in debug mode with hot reload
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter run -d web-server --debug --hot

# Build for web
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter build web

# Get Flutter version
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter --version
```

### 3. Scripts That Use System PATH
Scripts like [`run_e2e_tests.sh`](run_e2e_tests.sh:77) correctly use `flutter` without a full path, relying on the system PATH. This is acceptable IF the PATH is configured correctly.

### 4. IDE Configuration
IDE configuration files (`.idea/libraries/Dart_SDK.xml`, `.dart_tool/package_config.json`) should reference the correct Flutter path:
```
/Users/kimberlychan/Development/scentsafe-app/flutter/
```

## Files That May Need Updates

If you see references to the wrong path (`swipe-sauce/flutter`), these files need to be updated:

1. `.idea/libraries/Dart_SDK.xml`
2. `.dart_tool/package_config.json`
3. `ios/Flutter/Generated.xcconfig`
4. `ios/Flutter/flutter_export_environment.sh`
5. `macos/Flutter/Generated.xcconfig`
6. `macos/Flutter/flutter_export_environment.sh`

## Verification Commands

To verify you're using the correct Flutter installation:
```bash
# Check Flutter version and path
/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter --version

# Expected output should show:
# Flutter 3.24.3 • channel stable • https://github.com/flutter/flutter.git
# Framework • revision 2663184aa7 (1 year, 2 months ago) • 2024-09-11 16:27:48 -0500
```

## Terminal Sessions

When starting new terminal sessions for Flutter development:
1. Navigate to the project directory: `cd /Users/kimberlychan/Development/scentsafe-app/scentsafe`
2. Use the full Flutter path for all commands

## Common Mistakes to Avoid

1. ❌ Using `/Users/kimberlychan/Development/scentsafe-app/flutter/bin/flutter`
2. ❌ Assuming `flutter` command will use the correct installation without verifying PATH
3. ❌ Copying commands from other projects that may use different Flutter installations

## Best Practices

1. Always use the full path when executing Flutter commands
2. Verify the Flutter version matches the expected version (3.24.3)
3. Update any scripts or configuration files that reference the wrong path
4. When in doubt, run the version command to verify you're using the correct installation

## Project Structure Context

```
/Users/kimberlychan/Development/scentsafe-app/
├── flutter/          ← CORRECT Flutter installation
└── scentsafe/        ← Flutter project directory
    ├── lib/
    ├── ios/
    ├── android/
    └── ...
```

## Emergency Fix

If you accidentally run a command with the wrong path:
1. Stop any running processes (Ctrl+C)
2. Re-run the command with the correct path
3. Check if any configuration files were updated with the wrong path
4. Update configuration files if necessary

---

**REMINDER: The correct Flutter path is ALWAYS `/Users/kimberlychan/Development/scentsafe-app/flutter/` for this project!**