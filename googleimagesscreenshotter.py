import time
import io
import random
import math
from PIL import Image
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import os


def js_code_execute(driver):
    """Executes JavaScript to hide Google Maps UI elements."""
    js_string = """
        let overlays = document.querySelectorAll('earth-app, #toolbar, #search-card');
        for (let el of overlays) {
            if (el && el.shadowRoot) {}
        }
        let uiElements = document.querySelectorAll('.ui-container, .tool-panel');
        for (let el of uiElements) {
            if (el) { el.style.display = 'none'; }
        }
        """
    try:
        driver.execute_script(js_string)
    except Exception:
        pass


def screenshot(driver) -> Image:
    """Return a screenshot of the pure browser window content."""
    png = driver.get_screenshot_as_png()
    return Image.open(io.BytesIO(png))


def calculate_shot_count(min_lat, max_lat, min_long, max_long, shots_per_sq_km=5):
    """Calculates how many screenshots to take based on the area in square kilometers."""
    height_km = abs(max_lat - min_lat) * 111.32
    avg_lat_rad = math.radians((min_lat + max_lat) / 2)
    width_km = abs(max_long - min_long) * 111.32 * math.cos(avg_lat_rad)
    area_sq_km = height_km * width_km
    total_shots = round(area_sq_km * shots_per_sq_km)
    return max(1, total_shots)


# REMOVED zone_name argument
def generate_random_coords(min_lat, max_lat, min_long, max_long, count):
    """Generates a list of random coordinate dictionaries within a bounding box."""
    spots = []
    for _ in range(count):
        spots.append({
            "lat": random.uniform(min_lat, max_lat),
            "long": random.uniform(min_long, max_long)
        })
    return spots


def take_specific_screenshots(coordinate_list: list, sleep_time: float = 3):
    """Takes a screenshot for each coordinate, locked at 90m altitude."""

    output_dir = "/Users/mattracz/Projects/Bonachela_Lab/FC_screenshots/Australia/FC_4600"
    os.makedirs(output_dir, exist_ok=True)

    chrome_options = Options()
    chrome_options.add_argument('--disable-blink-features=AutomationControlled')
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    chrome_options.add_argument('--no-sandbox')
    chrome_options.add_argument('--disable-gpu-sandbox')
    chrome_options.add_argument('--disable-dev-shm-usage')
    chrome_options.add_argument('--enable-webgl')
    chrome_options.add_argument('--ignore-gpu-blocklist')

    driver = webdriver.Chrome(options=chrome_options)
    driver.maximize_window()
    target_w, target_h = 3000, 1150

    # REPLACED zone dictionary with a single global counter
    global_counter = 0

    with open("fairy_circles_log.txt", "w+") as f:
        f.write("Fairy Circles Screenshot Log (90m Altitude)\n")
        f.write("-" * 45 + "\n")

        for index, spot in enumerate(coordinate_list):
            lat = spot["lat"]
            long = spot["long"]

            # Increment the single counter
            global_counter += 1

            print(
                f"Processing {index + 1}/{len(coordinate_list)}: Image #{global_counter} (Lat {lat:.6f}, Long {long:.6f})")

            url = f'https://earth.google.com/web/@{lat},{long},1000a,90d,55y,0h,0t,0r'

            driver.get(url)
            time.sleep(4)
            js_code_execute(driver)
            time.sleep(sleep_time + 2)

            image = screenshot(driver)

            img_w, img_h = image.size
            left = (img_w - target_w) / 2
            top = (img_h - target_h) / 2
            right = (img_w + target_w) / 2
            bottom = (img_h + target_h) / 2

            image = image.crop((left, top, right, bottom))

            # The filename is now just "FC_" plus the global counter
            filename = f"FC_{global_counter}.png"

            full_save_path = os.path.join(output_dir, filename)
            image.save(full_save_path)

            f.write(f"{filename} -> Lat: {lat:.6f}, Long: {long:.6f} | URL: {url}\n")

    driver.close()
    driver.quit()
    print("All screenshots completed successfully!")


if __name__ == "__main__":

    # REMOVED "name" from the zones
    fairy_circle_zones = [
        {"min_lat": -23.392589, "max_lat": -23.378128, "min_long": 119.851549, "max_long": 119.864724},
        {"min_lat": -23.451708, "max_lat": -23.414730, "min_long": 119.838545, "max_long": 119.853765},
        {"min_lat": -23.548927, "max_lat": -23.379848, "min_long": 119.825513, "max_long": 119.860976},
        {"min_lat": -23.542796, "max_lat": -23.409688, "min_long": 119.846767, "max_long": 119.861392},
        {"min_lat": -23.563185, "max_lat": -23.544534, "min_long": 119.831683, "max_long": 119.850397},
        {"min_lat": -23.417927, "max_lat": -23.344655, "min_long": 120.405368, "max_long": 120.639129},
        {"min_lat": -23.454154, "max_lat": -22.775583, "min_long": 120.429190, "max_long": 120.693203}
    ]

    all_random_spots = []
    DENSITY_PER_SQ_KM = 2

    print("Calculating area and generating random coordinates...")

    # Using enumerate just to number the patches in the print statement
    for i, zone in enumerate(fairy_circle_zones):
        proportional_count = calculate_shot_count(
            zone["min_lat"], zone["max_lat"],
            zone["min_long"], zone["max_long"],
            shots_per_sq_km=DENSITY_PER_SQ_KM
        )

        print(f" -> Patch {i + 1} gets {proportional_count} screenshots.")

        spots = generate_random_coords(
            min_lat=zone["min_lat"], max_lat=zone["max_lat"],
            min_long=zone["min_long"], max_long=zone["max_long"],
            count=proportional_count
        )

        all_random_spots.extend(spots)

    print(f"\nTotal screenshots to take across all zones: {len(all_random_spots)}")
    print("Starting map generation...\n")

    take_specific_screenshots(
        coordinate_list=all_random_spots,
        sleep_time=0
    )