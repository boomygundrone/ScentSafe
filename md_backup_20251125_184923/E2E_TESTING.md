# End-to-End Testing with Playwright

This document explains how to set up and run end-to-end (E2E) tests for the ScentSafe Flutter application using Playwright.

## Overview

Playwright is a powerful E2E testing framework that allows you to test your Flutter web application across multiple browsers (Chromium, Firefox, WebKit) and devices. The tests simulate real user interactions and verify that your application works as expected.

## Prerequisites

Before running the E2E tests, make sure you have the following installed:

- Flutter SDK (already required for the project)
- Node.js (version 16 or higher)
- npm (comes with Node.js)

## Setup

### 1. Install Dependencies

The project includes a `package.json` file with the necessary Playwright dependencies. Install them with:

```bash
npm install
```

### 2. Install Playwright Browsers

Install the browser binaries required by Playwright:

```bash
npx playwright install
```

### 3. Build the Flutter Web App

The tests require a built version of your Flutter web application:

```bash
flutter build web --release
```

## Running Tests

### Using the Convenience Script

The easiest way to run tests is using the provided `run_e2e_tests.sh` script:

```bash
# Run tests in headless mode (default)
./run_e2e_tests.sh

# Run tests with visible browser
./run_e2e_tests.sh --headed

# Run tests in debug mode
./run_e2e_tests.sh --debug

# Run tests with specific browser
./run_e2e_tests.sh --browser firefox

# Start Playwright codegen for creating new tests
./run_e2e_tests.sh --codegen
```

### Using npm Scripts

You can also use the npm scripts defined in `package.json`:

```bash
# Run all tests
npm run test:e2e

# Run tests with visible browser
npm run test:e2e:headed

# Run tests in debug mode
npm run test:e2e:debug

# Generate new tests with codegen
npm run test:e2e:codegen

# View test reports
npm run test:e2e:report
```

### Using Playwright Directly

You can also run Playwright commands directly:

```bash
# Run all tests
npx playwright test

# Run specific test file
npx playwright test e2e/app.spec.ts

# Run tests with specific browser
npx playwright test --project=firefox

# Run tests in headed mode
npx playwright test --headed
```

## Test Structure

The E2E tests are located in the `e2e/` directory:

- `e2e/app.spec.ts` - Basic app functionality tests
- `e2e/detection.spec.ts` - Drowsiness detection feature tests

### Writing New Tests

1. Create a new `.spec.ts` file in the `e2e/` directory
2. Use the Playwright API to write your tests
3. Use the codegen tool to generate test code:

```bash
npx playwright codegen http://localhost:8080
```

### Test Configuration

The Playwright configuration is defined in `playwright.config.ts`:

- Tests run against multiple browsers (Chromium, Firefox, WebKit)
- Mobile viewports are also tested
- Screenshots and videos are captured on failure
- Tests run against a local server on port 8080

## Example Test

Here's an example of a basic test:

```typescript
import { test, expect } from '@playwright/test';

test('app loads correctly', async ({ page }) => {
  await page.goto('/');
  
  // Wait for the app to load
  await page.waitForLoadState('networkidle');
  
  // Check if the app title is visible
  await expect(page.locator('text=ScentSafe')).toBeVisible();
});
```

## Best Practices

1. **Use data-testid attributes**: Add `data-testid` attributes to your Flutter widgets for more reliable test selectors

2. **Wait for elements**: Use proper waiting strategies instead of fixed timeouts

3. **Test user flows**: Test complete user journeys rather than individual components

4. **Keep tests independent**: Each test should be able to run independently

5. **Use page objects**: For complex applications, consider using the Page Object Model pattern

## Debugging Tests

### Debug Mode

Run tests in debug mode to step through the test execution:

```bash
npx playwright test --debug
```

### Trace Viewer

View detailed traces of test execution:

```bash
npx playwright show-trace trace.zip
```

### VS Code Extension

Install the Playwright VS Code extension for a better development experience:

1. Install the "Playwright Test for VSCode" extension
2. Use the test explorer to run and debug tests
3. Get inline test results and error messages

## CI/CD Integration

To integrate E2E tests into your CI/CD pipeline:

1. Install Node.js and dependencies
2. Install Playwright browsers: `npx playwright install --with-deps`
3. Build the Flutter web app
4. Run the tests
5. Upload test reports as artifacts

Example GitHub Actions workflow:

```yaml
- name: Install dependencies
  run: npm install

- name: Install Playwright browsers
  run: npx playwright install --with-deps

- name: Build Flutter web app
  run: flutter build web --release

- name: Run E2E tests
  run: npx playwright test

- name: Upload test results
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: playwright-report
    path: playwright-report/
```

## Troubleshooting

### Common Issues

1. **Tests fail to find elements**: Make sure the app has fully loaded before trying to interact with elements

2. **Camera permissions**: Tests that require camera access may need special handling in the test environment

3. **Flaky tests**: Use proper waiting strategies and avoid fixed timeouts

4. **Browser not installed**: Run `npx playwright install` to install required browsers

### Getting Help

- Playwright documentation: https://playwright.dev/
- Flutter testing documentation: https://flutter.dev/docs/testing
- GitHub issues: Report issues in the project repository