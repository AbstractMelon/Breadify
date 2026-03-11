import os
import requests

PEXELS_API_KEY = 'BHxo1tt0UGQx8BUCVnebnUAvsS7yioCULjDKX80XEFSv99qhU1WDpx7k'

# List of all bread names from the expanded database
bread_names = [
    'Sourdough',
    'Baguette',
    'Ciabatta',
    'Naan',
    'Pumpernickel',
    'Challah',
    'Focaccia',
    'Pita',
    'Brioche',
    'Rye Bread',
    'Chapati',
    'Tortilla',
    'Injera',
    'Irish Soda Bread',
    'Pretzel',
    'Bagel',
    'English Muffin',
    'Lavash',
    'Arepa',
    'Damper',
    'Anadama Bread',
    'Pan de Sal',
    'Bolo do Caco',
    'Mantou',
    'Tiger Bread',
    'Fougasse',
    'Parker House Roll',
    'Bannock',
    'Crumpet',
    'Matzo',
    'Roti Canai',
    'Scone',
    'Cornbread',
    'Paneer Naan',
    'King Cake',
    'Quesadilla Base',
    'Laobing',
    'Parenyica',
    'Vetkoek',
    'Kanelbullar',
    'Lefse',
    'Bazlama',
    'Khachapuri',
    'Bolani',
    'Piadina',
    'Ketupat',
    'Slider Bun',
    'Frybread',
    'Shokupan',
    'Bara Brith',
    'Melonpan',
    'Pan de Muerto',
    'Babka',
    'Obi Non',
    'Pane Carasau',
    'Anpan',
    'Corn Tortilla',
    'Wheat Tortilla',
    'Bialy',
    'atanga',
]
# Create images directory if not exists
os.makedirs('images', exist_ok=True)

# Function to download image from Pexels
def download_bread_images():
    headers = {
        'Authorization': PEXELS_API_KEY
    }

    for name in bread_names:
        # Use a slightly more specific query for some names if needed,
        # but the name itself is usually sufficient for Pexels.
        query = name
        print(f'Searching Pexels for "{query}"...')

        response = requests.get(
            'https://api.pexels.com/v1/search',
            headers=headers,
            params={'query': query, 'per_page': 1} # Requesting only 1 image per bread type
        )

        if response.status_code == 200:
            data = response.json()
            if data['photos']:
                # Use 'large' or 'original' for potentially better quality if needed
                # 'medium' is good for smaller previews or faster downloads
                image_url = data['photos'][0]['src']['large']
                print(f'Downloading {name} from {image_url}...')

                try:
                    image_data = requests.get(image_url, stream=True) # Use stream for potentially large files
                    image_data.raise_for_status() # Raise an HTTPError for bad responses (4xx or 5xx)

                    # Create a clean filename: lowercase and replace spaces with underscores
                    filename = f'images/{name.lower().replace(" ", "_")}.jpg'

                    with open(filename, 'wb') as f:
                        for chunk in image_data.iter_content(chunk_size=8192): # Download in chunks
                            f.write(chunk)

                    print(f'Saved {filename}')

                except requests.exceptions.RequestException as e:
                    print(f'Failed to download image for {name}: {e}')

            else:
                print(f'No image found on Pexels for "{query}"')
        else:
            print(f'Failed to search Pexels for "{query}". Status code: {response.status_code}')
            print(f'Response: {response.text}') # Print response text for debugging

if __name__ == '__main__':
    download_bread_images()
