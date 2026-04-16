import random
import requests
import json
import urllib.parse
import re
import time

products_data = [
    ("iPhone 15 Pro Max", "Phones", "Apple's flagship titanium smartphone.", 134900, "IPhone_15_Pro"),
    ("iPhone 15", "Phones", "Dynamic Island and advanced camera system.", 79900, "IPhone_15"),
    ("iPhone 14", "Phones", "Reliable dual-camera Apple smartphone.", 59900, "IPhone_14"),
    ("iPhone 13", "Phones", "A15 Bionic chip and bright Super Retina XDR.", 49900, "IPhone_13"),
    ("Samsung Galaxy S24 Ultra", "Phones", "AI-powered flagship with S-Pen.", 129999, "Samsung_Galaxy_S24"),
    ("Samsung Galaxy S24", "Phones", "Compact powerhouse with Galaxy AI features.", 79999, "Samsung_Galaxy_S24"),
    ("Samsung Galaxy S23 Ultra", "Phones", "200MP camera and Snapdragon Gen 2.", 99999, "Samsung_Galaxy_S23"),
    ("Samsung Galaxy A54", "Phones", "Awesome 5G performance and display.", 35999, "Samsung_Galaxy_A54_5G"),
    ("Samsung Galaxy Z Fold 5", "Phones", "Premium foldable tablet-phone hybrid.", 154999, "Samsung_Galaxy_Z_Fold_5"),
    ("Samsung Galaxy Z Flip 5", "Phones", "Sleek clamshell foldable with large cover screen.", 99999, "Samsung_Galaxy_Z_Flip_5"),
    ("Google Pixel 8 Pro", "Phones", "Incredible computational photography and AI.", 106999, "Pixel_8"),
    ("Google Pixel 7a", "Phones", "Affordable A-series Pixel with stellar camera.", 43999, "Pixel_7a"),
    ("OnePlus 12", "Phones", "Smooth flagships with Hasselblad cameras.", 64999, "OnePlus_12"),
    ("OnePlus 11R", "Phones", "Performance-focused flagship killer.", 39999, "OnePlus_11"),
    ("Motorola Edge 40", "Phones", "Ultra-thin design with curved pOLED.", 29999, "Motorola_Edge_40"),
    ("Nothing Phone (2)", "Phones", "Unique transparent design with Glyph interface.", 44999, "Nothing_Phone_(2)"),
    ("Redmi Note 13 Pro+", "Phones", "200MP camera and 120W hypercharge.", 31999, "Redmi_Note_12"),
    ("Vivo X100 Pro", "Phones", "Zeiss optics. Dimensity 9300.", 89999, "Vivo_X_series"),
    ("iQOO 12", "Phones", "High-performance gaming phone.", 52999, "IQOO"),
    ("MacBook Pro 16 M3 Max", "Laptops", "Ultimate pro performance laptop by Apple.", 349900, "MacBook_Pro"),
    ("MacBook Air M2", "Laptops", "Strikingly thin and fast.", 114900, "MacBook_Air"),
    ("MacBook Air M1", "Laptops", "Best-in-class everyday laptop.", 84900, "MacBook_Air"),
    ("Dell XPS 13", "Laptops", "Premium ultrabook with infinity display.", 124990, "Dell_XPS"),
    ("Dell XPS 15", "Laptops", "Powerful creator laptop with OLED.", 189990, "Dell_XPS"),
    ("HP Spectre x360", "Laptops", "Elegant 2-in-1 convertible laptop.", 134999, "HP_Spectre"),
    ("HP Envy 15", "Laptops", "Creator-focused multimedia laptop.", 104999, "HP_Envy"),
    ("HP Pavilion 14", "Laptops", "Reliable mainstream notebook.", 64999, "HP_Pavilion"),
    ("Lenovo ThinkPad X1 Carbon", "Laptops", "The definitive business laptop.", 145990, "ThinkPad_X1_Carbon"),
    ("Lenovo Legion 5 Pro", "Laptops", "High-refresh-rate gaming powerhouse.", 135990, "IdeaPad"),
    ("Lenovo Yoga 7i", "Laptops", "Versatile 2-in-1 productivity machine.", 99990, "Lenovo_Yoga"),
    ("ASUS ROG Zephyrus G14", "Laptops", "Ultra-portable performance gaming.", 154990, "Republic_of_Gamers"),
    ("ASUS Zenbook 14 OLED", "Laptops", "Sleek and vibrant ultrabook.", 99990, "Zenbook"),
    ("ASUS TUF Gaming A15", "Laptops", "Durable budget gaming laptop.", 75990, "Asus"),
    ("Acer Predator Helios 300", "Laptops", "Hardcore gaming performance.", 119990, "Acer_Predator"),
    ("Acer Swift 3", "Laptops", "Lightweight budget productivity.", 59990, "Acer_Swift"),
    ("Microsoft Surface Pro 9", "Laptops", "Tablet versatility with laptop power.", 105990, "Surface_Pro_9"),
    ("Microsoft Surface Laptop 5", "Laptops", "Sleek touchscreen laptop.", 99990, "Surface_Laptop"),
    ("iPad Pro 12.9 Apple", "Tablets", "M2 chip with mini-LED display.", 112900, "IPad_Pro"),
    ("iPad Air 5 Apple", "Tablets", "Light and powerful with M1.", 59900, "IPad_Air"),
    ("iPad 10th gen", "Tablets", "Redesigned entry-level iPad.", 39900, "IPad_(10th_generation)"),
    ("Samsung Galaxy Tab S9 Ultra", "Tablets", "Massive AMOLED Android tablet.", 119999, "Samsung_Galaxy_Tab_series"),
    ("Lenovo Tab P11", "Tablets", "Great for streaming and light work.", 24999, "Lenovo"),
    ("Sony PlayStation 5 Console", "Gaming", "Next-gen console gaming by Sony.", 49990, "PlayStation_5"),
    ("Xbox Series X Console", "Gaming", "Most powerful Xbox console.", 49990, "Xbox_Series_X_and_Series_S"),
    ("Nintendo Switch OLED Console", "Gaming", "Vibrant handheld and home console.", 34990, "Nintendo_Switch"),
    ("Steam Deck OLED Console", "Gaming", "Premium portable PC gaming.", 59990, "Steam_Deck"),
    ("Meta Quest 3 VR", "Gaming", "Mixed reality VR headset.", 49990, "Meta_Quest_Pro"),
    ("Playstation DualSense Wireless Controller", "Accessories", "Haptic feedback PS5 controller.", 5990, "DualSense"),
    ("Xbox Wireless Controller", "Accessories", "Ergonomic gaming controller.", 5490, "Xbox_Wireless_Controller"),
    ("Sony WH-1000XM5", "Audio", "Industry-leading noise cancellation.", 29990, "Sony_WH-1000XM5"),
    ("Sony WH-1000XM4", "Audio", "Excellent folding noise-cancelling headphones.", 22990, "Sony_WH-1000XM4"),
    ("Sony WF-1000XM5 earbuds", "Audio", "Premium noise-cancelling earbuds.", 24990, "Sony"),
    ("Apple AirPods Pro 2nd Gen", "Audio", "Rich audio with active noise cancellation.", 24900, "AirPods_Pro"),
    ("Bose QuietComfort Ultra headphones", "Audio", "World-class spatialized noise cancellation.", 35900, "Bose_headphones"),
    ("JBL Flip 6 speaker", "Audio", "Bold sound for every adventure.", 11999, "JBL"),
    ("JBL Charge 5 speaker", "Audio", "Portable speaker with built-in powerbank.", 14999, "JBL"),
    ("Apple Watch Ultra 2 smartwatch", "Wearables", "Rugged and capable smartwatch.", 89900, "Apple_Watch"),
    ("Apple Watch Series 9", "Wearables", "Smarter, brighter, and more powerful.", 41900, "Apple_Watch"),
    ("Samsung Galaxy Watch 6 Classic", "Wearables", "Iconic rotating bezel smartwatch.", 36999, "Samsung_Galaxy_Watch_series"),
    ("Garmin Fenix 7 Pro smartwatch", "Wearables", "Multisport solar GPS watch.", 84990, "Garmin_Fenix"),
    ("LG OLED C3 65-inch TV", "TVs", "Incredible self-lit pixels and pure black.", 169990, "OLED"),
    ("Sony Bravia XR A80L 65-inch TV", "TVs", "Cognitive Processor XR OLED.", 219990, "Bravia_(brand)"),
    ("Samsung Neo QLED 4K 55-inch TV", "TVs", "Quantum Matrix Technology brilliance.", 124990, "Quantum_dot_display"),
    ("Sony Alpha 7 IV camera", "Cameras", "Hybrid full-frame mirrorless camera.", 199990, "Sony_Alpha_7_IV"),
    ("Sony Alpha 7S III camera", "Cameras", "The ultimate video-centric mirrorless.", 299990, "Sony_Alpha_7S_III"),
    ("Canon EOS R6 Mark II camera", "Cameras", "Fast and versatile mirrorless master.", 214990, "Canon_EOS_R6"),
    ("GoPro HERO12 Black camera", "Cameras", "The ultimate action camera.", 39990, "GoPro"),
    ("DJI Mini 4 Pro drone", "Cameras", "Mini camera drone with omnidirectional sensing.", 84990, "DJI"),
]

def get_amazon_image(query):
    url = f"https://www.amazon.in/s?k={urllib.parse.quote(query)}"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept-Language": "en-US,en;q=0.9",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
        "Referer": "https://www.amazon.in/"
    }
    try:
        r = requests.get(url, headers=headers, timeout=5)
        if r.status_code == 200:
            # We want slightly larger images so we strip the size constraint bounding _AC_UY218_
            match = re.search(r'class="s-image"[^>]*src="(https://m\.media-amazon\.com/images/I/[^"]+\.jpg)"', r.text)
            if match:
                raw_url = match.group(1)
                # Convert thumbnail _AC_UY218_ to higher res _AC_UY500_
                high_res = re.sub(r'\_AC_UY[0-9]+\_', '_AC_UY500_', raw_url)
                return high_res
    except Exception as e:
        pass
    return None

generic_images = {
    "Phones": "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?q=80&w=1000",
    "Laptops": "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?q=80&w=1000",
    "Tablets": "https://images.unsplash.com/photo-1561154464-82e9adf32764?q=80&w=1000",
    "Gaming": "https://images.unsplash.com/photo-1486401899868-0e435ed85128?q=80&w=1000",
    "Accessories": "https://images.unsplash.com/photo-1527814050087-379381547994?q=80&w=1000",
    "Audio": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=1000",
    "Wearables": "https://images.unsplash.com/photo-1602174528367-7ed9fc0737e4?q=80&w=1000",
    "TVs": "https://images.unsplash.com/photo-1593784991095-a205069470b6?q=80&w=1000",
    "Cameras": "https://images.unsplash.com/photo-1516035069371-29a1b244cc32?q=80&w=1000"
}

def generate_price_history(base_price, is_amazon=True):
    history = []
    current = base_price * 1.05 
    bias = -0.0018 if is_amazon else -0.0022
    if not is_amazon: 
        current = current * 0.985 
    for _ in range(14):
        history.append(int(current))
        fluct = random.uniform(-0.01, 0.01) + bias
        current = current * (1 + fluct)
        
    history.reverse()
    history[-1] = int(base_price if is_amazon else base_price * 0.98)
    return history

dart_content = '''import '../models/simulated_product.dart';

final List<SimulatedProduct> generatedProducts = [
'''

print("Generating 60+ core items with pure Amazon web links...")
for idx, p in enumerate(products_data):
    name, category, desc, base_price, wiki_title = p
    pid = f"prod_real_{str(idx).zfill(3)}"
    
    # Target straight to amazon search for perfection!
    img = get_amazon_image(name)
    if not img:
        img = generic_images.get(category, generic_images["Accessories"])
    
    amz_hist = generate_price_history(base_price, True)
    flp_hist = generate_price_history(base_price, False)
    
    rating = round(random.uniform(4.0, 4.9), 1)
    reviews = random.randint(300, 15000)
    clean_desc = desc.replace('"', '\\"')
    
    dart_content += f'''  SimulatedProduct(
    id: '{pid}',
    name: "{name}",
    category: '{category}',
    description: "{clean_desc}",
    imageUrl: '{img}',
    rating: {rating},
    reviews: {reviews},
    amazonPriceHistory: {amz_hist},
    flipkartPriceHistory: {flp_hist},
    lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
  ),
'''
    print(f"[{idx+1}/{len(products_data)}] Processed {name}")
    # Throttle slightly to avoid fast block
    time.sleep(0.5)

dart_content += '];\n'

with open('lib/services/simulated_data.dart', 'w', encoding='utf-8') as f:
    f.write(dart_content)

print("Generated simulated_data.dart with real Amazon HD photos successfully!")
