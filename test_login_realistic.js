const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: [
      '--disable-blink-features=AutomationControlled',
      '--disable-dev-shm-usage',
      '--disable-web-security',
      '--disable-features=IsolateOrigins,site-per-process'
    ]
  });
  
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    viewport: { width: 1920, height: 1080 },
    locale: 'en-US',
    timezoneId: 'America/New_York',
    // Remove automation flags
    bypassCSP: true,
    ignoreHTTPSErrors: true
  });
  
  // Add init script to hide automation
  await context.addInitScript(() => {
    Object.defineProperty(navigator, 'webdriver', {
      get: () => undefined,
    });
    
    // Mock plugins
    Object.defineProperty(navigator, 'plugins', {
      get: () => [1, 2, 3, 4, 5],
    });
    
    // Mock languages
    Object.defineProperty(navigator, 'languages', {
      get: () => ['en-US', 'en'],
    });
  });
  
  const page = await context.newPage();
  
  try {
    console.log('Navigating to friendbet.526462738.xyz...');
    
    // Set realistic headers
    await page.setExtraHTTPHeaders({
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Cache-Control': 'max-age=0',
      'Sec-Fetch-Dest': 'document',
      'Sec-Fetch-Mode': 'navigate',
      'Sec-Fetch-Site': 'none',
      'Sec-Fetch-User': '?1',
      'Upgrade-Insecure-Requests': '1'
    });
    
    await page.goto('https://friendbet.526462738.xyz', { 
      waitUntil: 'domcontentloaded',
      timeout: 30000 
    });
    
    // Wait for page to load completely
    await page.waitForTimeout(5000);
    
    // Check current URL (might redirect for Cloudflare)
    const currentUrl = page.url();
    console.log('Current URL:', currentUrl);
    
    const title = await page.title();
    console.log('Page title:', title);
    
    // Look for login elements with broader search
    const pageContent = await page.content();
    
    // Check if we're still on Cloudflare challenge page
    if (title.includes('Just a moment') || pageContent.includes('challenge-platform')) {
      console.log('Still on Cloudflare challenge page');
      
      // Try to wait for challenge to complete
      console.log('Waiting 10 seconds for Cloudflare challenge...');
      await page.waitForTimeout(10000);
      
      // Check again
      const newTitle = await page.title();
      console.log('New page title:', newTitle);
      
      if (newTitle.includes('Just a moment')) {
        console.log('Cloudflare challenge not passed in headless mode');
        console.log('Suggestions:');
        console.log('1. Add WAF rule in Cloudflare dashboard to allow Playwright user agent');
        console.log('2. Use non-headless mode with xvfb-run');
        console.log('3. Test on staging environment without Cloudflare');
      }
    } else {
      console.log('Successfully loaded page!');
      
      // Look for login functionality
      const loginLinks = await page.$$('[href*="oauth"], [href*="login"], [href*="google"], [href*="github"]');
      console.log(`Found ${loginLinks.length} login-related links`);
      
      for (const link of loginLinks) {
        const text = await link.textContent();
        const href = await link.getAttribute('href');
        console.log(`Link: "${text?.trim()}" -> ${href}`);
      }
      
      // Take screenshot
      await page.screenshot({ path: 'friendbet-login-page.png', fullPage: true });
      console.log('Screenshot saved to friendbet-login-page.png');
    }
    
  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await browser.close();
  }
  
  console.log('Test completed');
})();