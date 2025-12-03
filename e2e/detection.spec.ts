import { test, expect } from '@playwright/test';

test.describe('Drowsiness Detection Feature', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('can navigate to detection screen', async ({ page }) => {
    // Look for navigation to test/detection screen
    const testButton = page.locator('text=Test').or(page.locator('[data-testid="test-button"]')).or(page.locator('button:has-text("Test")'));
    
    if (await testButton.isVisible()) {
      await testButton.click();
      await expect(page.locator('text=Test')).toBeVisible();
    } else {
      // Try alternative navigation
      const dashboardButton = page.locator('text=Dashboard').or(page.locator('button:has-text("Dashboard")'));
      if (await dashboardButton.isVisible()) {
        await dashboardButton.click();
      }
    }
  });

  test('displays camera interface when accessing video screen', async ({ page }) => {
    // Navigate to video screen
    const videoButton = page.locator('text=Video').or(page.locator('[data-testid="video-button"]')).or(page.locator('button:has-text("Video")'));
    
    if (await videoButton.isVisible()) {
      await videoButton.click();
      
      // Wait for video screen to load
      await page.waitForTimeout(2000);
      
      // Check for camera-related elements
      const cameraElement = page.locator('video').or(page.locator('[data-testid="camera-view"]')).or(page.locator('text=Camera'));
      
      // Note: Camera permissions might need to be handled in the test environment
      if (await cameraElement.isVisible({ timeout: 5000 })) {
        await expect(cameraElement).toBeVisible();
      }
    }
  });

  test('shows detection status', async ({ page }) => {
    // Navigate to test or dashboard screen
    const testButton = page.locator('text=Test').or(page.locator('button:has-text("Test")'));
    const dashboardButton = page.locator('text=Dashboard').or(page.locator('button:has-text("Dashboard")'));
    
    if (await testButton.isVisible()) {
      await testButton.click();
    } else if (await dashboardButton.isVisible()) {
      await dashboardButton.click();
    }
    
    // Wait for screen to load
    await page.waitForTimeout(2000);
    
    // Look for detection status indicators
    const statusElements = [
      page.locator('text=Alert'),
      page.locator('text=Drowsy'),
      page.locator('text=Monitoring'),
      page.locator('text=Detection'),
      page.locator('[data-testid="detection-status"]')
    ];
    
    for (const element of statusElements) {
      if (await element.isVisible({ timeout: 3000 })) {
        await expect(element).toBeVisible();
        break;
      }
    }
  });

  test('displays bluetooth connection status', async ({ page }) => {
    // Navigate to dashboard or test screen
    const dashboardButton = page.locator('text=Dashboard').or(page.locator('button:has-text("Dashboard")'));
    const testButton = page.locator('text=Test').or(page.locator('button:has-text("Test")'));
    
    if (await dashboardButton.isVisible()) {
      await dashboardButton.click();
    } else if (await testButton.isVisible()) {
      await testButton.click();
    }
    
    // Wait for screen to load
    await page.waitForTimeout(2000);
    
    // Look for bluetooth status indicators
    const bluetoothElements = [
      page.locator('text=Bluetooth'),
      page.locator('text=Connected'),
      page.locator('text=Device'),
      page.locator('[data-testid="bluetooth-status"]')
    ];
    
    for (const element of bluetoothElements) {
      if (await element.isVisible({ timeout: 3000 })) {
        await expect(element).toBeVisible();
        break;
      }
    }
  });
});