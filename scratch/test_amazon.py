import requests
import urllib.parse
import re

def get_amazon_image(query):
    url = f"https://www.amazon.in/s?k={urllib.parse.quote(query)}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Referer": "https://www.amazon.in/"
    }
    r = requests.get(url, headers=headers, timeout=10)
    print(f"Status Code: {r.status_code}")
    if r.status_code == 200:
        match = re.search(r'class="s-image"[^>]*src="(https://m\.media-amazon\.com/images/I/[^"]+\.jpg)"', r.text)
        if match:
            return match.group(1)
    elif r.status_code == 503:
        print("Blocked by Amazon CAPTCHA/Bot protection.")
    return None

print("MacBook Pro 16:", get_amazon_image("MacBook Pro 16 M3 Max"))
