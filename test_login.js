const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ 
    headless: true,
    args: ['--disable-blink-features=AutomationControlled']
  });
  const page = await browser.newPage();
  
  try {
    console.log('Navigating to friendbet.526462738.xyz...');
    await page.goto('https://friendbet.526462738.xyz', { waitUntil: 'domcontentloaded', timeout: 60000 });
    
    // Wait for Cloudflare challenge to complete
    console.log('Waiting for page to fully load (may handle Cloudflare challenge)...');
    await page.waitForTimeout(10000);
    
    // Wait for either Cloudflare to clear or real content to appear
    await page.waitForFunction(() => {
      return !document.title.includes('Just a moment') || document.body.innerText.includes('login') || document.body.innerText.includes('Login');
    }, { timeout: 30000 }).catch(() => console.log('Timeout waiting for Cloudflare, continuing anyway...'));
    
    console.log('Page loaded. Checking for login elements...');
    const title = await page.title();
    console.log('Page title:', title);
    
    // Look for OAuth login buttons
    const oauthButtons = await page.$$('a[href*="oauth"], button:has-text("Login"), a:has-text("Login"), button:has-text("Sign")');
    console.log(`Found ${oauthButtons.length} potential login elements`);
    
    // Take a screenshot
    await page.screenshot({ path: 'login-page.png' });
    console.log('Screenshot saved to login-page.png');
    
    // Check URL structure
    const url = page.url();
    console.log('Current URL:', url);
    
    // Look for specific OAuth provider links
    const googleLogin = await page.$('a[href*="google"]');
    const githubLogin = await page.$('a[href*="github"]');
    const microsoftLogin = await page.$('a[href*="microsoft"]');
    
    console.log('Google OAuth:', googleLogin ? 'Found' : 'Not found');
    console.log('GitHub OAuth:', githubLogin ? 'Found' : 'Not found');
    console.log('Microsoft OAuth:', microsoftLogin ? 'Found' : 'Not found');
    
    if (googleLogin) {
      const googleHref = await googleLogin.getAttribute('href');
      console.log('Google OAuth URL:', googleHref);
    }
    
  } catch (error) {
    console.error('Error during test:', error.message);
  } finally {
    await browser.close();
  }
  
  console.log('Test completed');
})();