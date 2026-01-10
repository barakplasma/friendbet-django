import asyncio
from playwright.async_api import async_playwright
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def test_login():
    async with async_playwright() as p:
        # Launch browser in headless mode
        browser = await p.chromium.launch(headless=True)
        context = await browser.new_context()
        page = await context.new_page()
        
        try:
            # Navigate to the website
            logger.info("Navigating to friendbet.526462738.xyz")
            await page.goto("https://friendbet.526462738.xyz", timeout=30000)
            
            # Wait for page to load
            await page.wait_for_load_state("networkidle", timeout=10000)
            logger.info(f"Page title: {await page.title()}")
            logger.info(f"Current URL: {page.url}")
            
            # Check if there are login buttons or OAuth providers
            logger.info("Looking for login elements...")
            
            # Look for common OAuth login buttons
            oauth_selectors = [
                "a[href*='oauth']",
                "button[contains(text(), 'Login')]",
                "button[contains(text(), 'Sign in')]",
                "a[contains(text(), 'Google')]",
                "a[contains(text(), 'GitHub')]",
                "a[contains(text(), 'Microsoft')]",
                ".login-button",
                ".oauth-button",
                "[data-provider='google']",
                "[data-provider='github']",
                "[data-provider='microsoft']"
            ]
            
            found_elements = []
            for selector in oauth_selectors:
                try:
                    elements = await page.locator(selector).all()
                    if elements:
                        found_elements.extend([(selector, len(elements))])
                        logger.info(f"Found {len(elements)} elements matching: {selector}")
                except Exception:
                    pass
            
            if not found_elements:
                logger.info("No obvious login buttons found. Checking page content...")
                
                # Get page text content
                body_text = await page.evaluate("() => document.body.innerText")
                logger.info(f"Page text preview: {body_text[:500]}...")
                
                # Check for any links
                links = await page.locator("a").all()
                logger.info(f"Found {len(links)} links on the page")
                
                for i, link in enumerate(links[:10]):  # Show first 10 links
                    try:
                        text = await link.inner_text()
                        href = await link.get_attribute("href")
                        logger.info(f"Link {i+1}: {text.strip()} -> {href}")
                    except:
                        pass
            
            # Take a screenshot for debugging
            await page.screenshot(path="login_page_screenshot.png")
            logger.info("Screenshot saved as login_page_screenshot.png")
            
            # Check HTTP status
            response = await page.goto("https://friendbet.526462738.xyz")
            if response:
                logger.info(f"HTTP Status: {response.status}")
            
            logger.info("Test completed - check logs above for findings")
            
        except Exception as e:
            logger.error(f"Error during test: {str(e)}")
        finally:
            await browser.close()

if __name__ == "__main__":
    asyncio.run(test_login())