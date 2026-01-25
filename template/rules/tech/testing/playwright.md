# Playwright Patterns

> E2E testing with real browsers.

## Test Structure

```typescript
import { test, expect } from '@playwright/test';

test.describe('Feature', () => {
  test('should work', async ({ page }) => {
    await page.goto('/path');
    await expect(page.getByRole('heading')).toContainText('Title');
  });
});
```

## Locator Strategies

Prefer accessible locators:

```typescript
// Good - accessible, resilient
page.getByRole('button', { name: 'Submit' })
page.getByLabel('Email')
page.getByText('Welcome')
page.getByTestId('submit-form')

// Avoid - brittle
page.locator('.btn-primary')
page.locator('#submit')
page.locator('div > button:first-child')
```

## Waiting

Playwright auto-waits, but sometimes explicit waits help:

```typescript
// Wait for navigation
await page.waitForURL('/dashboard');

// Wait for network idle
await page.waitForLoadState('networkidle');

// Wait for element
await page.getByRole('button').waitFor();

// Wait for response
await page.waitForResponse(resp => resp.url().includes('/api/'));
```

## Assertions

```typescript
// Visibility
await expect(element).toBeVisible();
await expect(element).toBeHidden();

// Content
await expect(element).toHaveText('Expected');
await expect(element).toContainText('partial');

// Attributes
await expect(element).toHaveAttribute('href', '/path');
await expect(element).toBeDisabled();

// Page
await expect(page).toHaveURL('/expected');
await expect(page).toHaveTitle('Title');
```

## Authentication

Use fixtures for authenticated tests:

```typescript
// fixtures.ts
import { test as base } from '@playwright/test';

export const test = base.extend({
  authenticatedPage: async ({ page }, use) => {
    // Login logic
    await page.goto('/auth/sign-in');
    await page.fill('[name=email]', 'test@example.com');
    await page.fill('[name=password]', 'password');
    await page.click('button[type=submit]');
    await page.waitForURL('/dashboard');

    await use(page);
  },
});
```

## Common Commands

```bash
npm run test:e2e           # Run all E2E tests
npm run test:e2e:ui        # Interactive UI
npm run test:e2e:headed    # Visible browser
npx playwright test path/  # Run specific folder
npx playwright show-report # View HTML report
```

## Serial Mode

Use for tests that share state:

```typescript
test.describe.serial('Destructive tests', () => {
  test('first', async ({ page }) => { /* ... */ });
  test('depends on first', async ({ page }) => { /* ... */ });
});
```

## Danger Zone

| Never | Consequence |
|-------|-------------|
| CSS selectors as primary strategy | Brittle tests break on style changes |
| Hardcoded waits (`page.waitForTimeout`) | Flaky tests, slow CI |
| Share mutable state between workers | Race conditions |
| Skip browser cleanup | Memory leaks in CI |
