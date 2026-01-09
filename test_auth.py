import asyncio
from playwright.async_api import async_playwright

async def test_signup():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()
        
        # Test signup
        await page.goto('http://localhost:8001/signup/')
        await page.screenshot(path='/tmp/signup_page.png')
        
        # Fill out the signup form
        await page.fill('input[name="username"]', 'testuser')
        await page.fill('input[name="password1"]', 'testpass123')
        await page.fill('input[name="password2"]', 'testpass123')
        
        # Submit the form
        await page.click('button[type="submit"]')
        await page.wait_for_url('http://localhost:8001/')
        
        # Check if we're logged in
        current_url = page.url
        print(f"After signup, current URL: {current_url}")
        
        await page.screenshot(path='/tmp/after_signup.png')
        
        # Test logout
        await page.goto('http://localhost:8001/logout/')
        
        # Test login
        await page.goto('http://localhost:8001/login/')
        await page.fill('input[name="username"]', 'testuser')
        await page.fill('input[name="password"]', 'testpass123')
        await page.click('button[type="submit"]')
        await page.wait_for_url('http://localhost:8001/')
        
        current_url = page.url
        print(f"After login, current URL: {current_url}")
        await page.screenshot(path='/tmp/after_login.png')
        
        await browser.close()
        print("Test completed successfully!")

if __name__ == "__main__":
    asyncio.run(test_signup())