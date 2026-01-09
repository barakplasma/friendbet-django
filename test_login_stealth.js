const { chromium } = require('playwright-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');

(async () => {
  // Add stealth plugin to avoid detection
  chromium.use(StealthPlugin());
  
  const browser = await chromium.launch({ 
    headless: true,
    args: [
      '--disable-blink-features=AutomationControlled',
      '--disable-dev-shm-usage',
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process'
    ]
  });
  
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    viewport: { width: 1920, height: 1080 },
    locale: 'en-US',
    timezoneId: 'America/New_York',
    permissions: ['geolocation', 'notifications']
  });
  
  const page = await context.newPage();
  
  // Add extra headers to appear more like a real browser
  await page.setExtraHTTPHeaders({
    'Accept-Language': 'en-US,en;q=0.9',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1'
  });
  
  try {
    console.log('Navigating to friendbet.526462738.xyz with stealth mode...');
    await page.goto('https://friendbet.526462738.xyz', { 
      waitUntil: 'networkidle',
      timeout: 60000 
    });
    
    console.log('Page loaded. Checking for login elements...');
    const title = await page.title();
    console.log('Page title:', title);
    
    // Look for OAuth login buttons with broader selectors
    const loginSelectors = [
      'a[href*="oauth"]',
      'a[href*="google"]', 
      'a[href*="github"]',
      'a[href*="microsoft"]',
      'button:has-text("Login")',
      'a:has-text("Login")',
      'button:has-text("Sign")',
      '.login-button',
      '.oauth-button'
    ];
    
    let foundElements = [];
    for (const selector of loginSelectors) {
      const elements = await page.$$(selector);
      if (elements.length > 0) {
        foundElements.push({ selector, count: elements.length });
        for (const el of elements) {
          const text = await el.textContent();
          const href = await el.getAttribute('href');
          console.log(`Found element: ${selector} - Text: "${text?.trim()}" - Href: ${href}`);
        }
      }
    }
    
    console.log(`Found ${foundElements.length} selector matches:`, foundElements);
    
    // Take a screenshot
    await page.screenshot({ path: 'login-page-stealth.png', fullPage: true });
    console.log('Screenshot saved to login-page-stealth.png');
    
    // Get page content for debugging
    const bodyText = await page.evaluate(() => document.body.innerText);
    if (bodyText.includes('Cloudflare') || bodyText.includes('challenge')) {
      console.log('Still encountering Cloudflare challenge');
    }
    
  } catch (error) {
    console.error('Error during test:', error.message);
  } finally {
    await browser.close();
  }
  
  console.log('Test completed');
})();