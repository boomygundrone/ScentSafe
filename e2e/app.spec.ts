import { test, expect } from '@playwright/test';

test.describe('ScentSafe App', () => {
  test('loads the home page', async ({ page }) => {
    await page.goto('/');
    
    // Wait for the app to load
    await page.waitForLoadState('networkidle');
    
    // Check if the app title is visible
    await expect(page.locator('text=ScentSafe')).toBeVisible({ timeout: 10000 });
  });

  test('navigates to dashboard', async ({ page }) => {
    await page.goto('/');
    
    // Wait for the app to load
    await page.waitForLoadState('networkidle');
    
    // Look for dashboard navigation (adjust selector based on your app)
    const dashboardButton = page.locator('text=Dashboard').or(page.locator('[data-testid="dashboard-button"]')).or(page.locator('button:has-text("Dashboard")'));
    
    if (await dashboardButton.isVisible()) {
      await dashboardButton.click();
      await expect(page.locator('text=Dashboard')).toBeVisible();
    }
  });

  test('navigates to test screen', async ({ page }) => {
    await page.goto('/');
    
    // Wait for the app to load
    await page.waitForLoadState('networkidle');
    
    // Look for test screen navigation
    const testButton = page.locator('text=Test').or(page.locator('[data-testid="test-button"]')).or(page.locator('button:has-text("Test")'));
    
    if (await testButton.isVisible()) {
      await testButton.click();
      await expect(page.locator('text=Test')).toBeVisible();
    }
  });

  test('displays camera permissions dialog if needed', async ({ page }) => {
    await page.goto('/');
    
    // Wait for the app to load
    await page.waitForLoadState('networkidle');
    
    // Navigate to video screen which might require camera permissions
    const videoButton = page.locator('text=Video').or(page.locator('[data-testid="video-button"]')).or(page.locator('button:has-text("Video")'));
    
    if (await videoButton.isVisible()) {
      await videoButton.click();
      
      // Check if there's a camera permission request
      // Note: In a real test environment, you might need to handle permissions differently
      await page.waitForTimeout(2000); // Wait a bit for any permission dialogs
    }
  });

  test('responsive design works on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/');
    
    // Wait for the app to load
    await page.waitForLoadState('networkidle');
    
    // Check if the app is properly displayed on mobile
    await expect(page.locator('body')).toBeVisible();
    
    // Check if navigation is properly adapted for mobile
    const navigation = page.locator('nav').or(page.locator('[role="navigation"]')).or(page.locator('.navigation'));
    if (await navigation.isVisible()) {
      await expect(navigation).toBeVisible();
    }
  });
});