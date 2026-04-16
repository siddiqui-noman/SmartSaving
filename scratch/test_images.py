import requests

def get_wiki_image(title):
    url = f"https://en.wikipedia.org/w/api.php?action=query&titles={title}&prop=pageimages&format=json&pithumbsize=1000"
    try:
        r = requests.get(url, headers={"User-Agent": "SmartSavingAppBot/1.0"})
        data = r.json()
        pages = data['query']['pages']
        for page_id in pages:
            if 'thumbnail' in pages[page_id]:
                return pages[page_id]['thumbnail']['source']
    except Exception as e:
        print(f"Error: {e}")
    return None

print("iPhone 15:", get_wiki_image("IPhone_15"))
print("MacBook Pro:", get_wiki_image("MacBook_Pro"))
print("PlayStation 5:", get_wiki_image("PlayStation_5"))
print("Sony WH-1000XM5:", get_wiki_image("Sony_WH-1000XM5"))
print("Samsung Galaxy S24:", get_wiki_image("Samsung_Galaxy_S24"))
