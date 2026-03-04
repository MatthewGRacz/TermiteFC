import time
import io
import random
import math
from PIL import Image
from selenium import webdriver


def js_code_execute(driver):
    """Executes JavaScript to hide Google Maps UI elements."""
    js_string = """
    let layersBtn = document.querySelector('button[aria-label="Layers"]');
    if (layersBtn) { layersBtn.click(); }

    setTimeout(function() {
        let moreBtn = document.querySelector('button[aria-label="More"]');
        if (moreBtn) { moreBtn.click(); }

        setTimeout(function() {
            let buttons = document.querySelectorAll('button');
            for (let btn of buttons) {
                if (btn.innerText.includes("Labels") && btn.getAttribute('aria-checked') === 'true') {
                    btn.click();
                }
                if (btn.innerText.includes("Globe") && btn.getAttribute('aria-checked') === 'true') {
                    btn.click();
                }
            }

            let uiElements = document.querySelectorAll('#omnibox-container, #QA0Szd, .widget-pane, .gmnoprint, .scene-footer-container, #watermark, #minimap');
            for (let el of uiElements) {
                if (el) { el.style.display = 'none'; }
            }

            let closeBtn = document.querySelector('button[aria-label="Close"]');
            if (closeBtn) { closeBtn.click(); }

        }, 800);
    }, 800);
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
    # 1 degree of latitude is ~111.32 km
    height_km = abs(max_lat - min_lat) * 111.32

    # 1 degree of longitude is ~111.32 km * cos(latitude in radians)
    avg_lat_rad = math.radians((min_lat + max_lat) / 2)
    width_km = abs(max_long - min_long) * 111.32 * math.cos(avg_lat_rad)

    # Calculate total area in square kilometers
    area_sq_km = height_km * width_km

    # Multiply area by your desired density and round to nearest whole number
    total_shots = round(area_sq_km * shots_per_sq_km)

    # Ensure it always takes at least 1 screenshot, even for tiny patches
    return max(1, total_shots)


def generate_random_coords(zone_name, min_lat, max_lat, min_long, max_long, count):
    """Generates a list of random coordinate dictionaries within a bounding box."""
    spots = []
    for _ in range(count):
        rand_lat = random.uniform(min_lat, max_lat)
        rand_long = random.uniform(min_long, max_long)
        spots.append({
            "zone": zone_name,
            "lat": rand_lat,
            "long": rand_long
        })
    return spots


def take_specific_screenshots(coordinate_list: list, sleep_time: float = 3):
    """Takes a 740x400 screenshot for each coordinate, locked at 185m altitude."""

    driver = webdriver.Chrome()
    driver.maximize_window()
    target_w, target_h = 1000,1000

    # Dictionary to keep track of image numbers for each zone (e.g., Patch_A_1, Patch_A_2)
    zone_counters = {}

    with open("fairy_circles_log.txt", "w+") as f:
        f.write("Fairy Circles Screenshot Log (90m Altitude)\n")
        f.write("-" * 45 + "\n")

        for index, spot in enumerate(coordinate_list):
            zone = spot["zone"]
            lat = spot["lat"]
            long = spot["long"]

            # Update the counter for this specific zone
            zone_counters[zone] = zone_counters.get(zone, 0) + 1
            image_number = zone_counters[zone]

            print(
                f"Processing {index + 1}/{len(coordinate_list)}: {zone} #{image_number} (Lat {lat:.6f}, Long {long:.6f})")

            # Format URL with hardcoded 90m altitude
            url = f'https://www.google.com/maps/@{lat},{long},90m/data=!3m1!1e3?force=canvas'

            driver.get(url)
            time.sleep(1)

            js_code_execute(driver)
            time.sleep(sleep_time)

            image = screenshot(driver)

            # --- CROP LOGIC ---
            img_w, img_h = image.size
            left = (img_w - target_w) / 2
            top = (img_h - target_h) / 2
            right = (img_w + target_w) / 2
            bottom = (img_h + target_h) / 2

            image = image.crop((left, top, right, bottom))
            # ------------------

            filename = f"{zone}_{image_number}.png"
            image.save(filename)

            f.write(f"{filename} -> Lat: {lat:.6f}, Long: {long:.6f} | URL: {url}\n")

    driver.close()
    driver.quit()
    print("All screenshots completed successfully!")


if __name__ == "__main__":

    # 1. DEFINE YOUR ZONES (Bounding Boxes)
    # Replace these coordinates with your actual Australian Fairy Circle patches
    fairy_circle_zones = [
        {
            "name": "FC_1",
            "min_lat": -23.554890, "max_lat": -23.548332,
            "min_long": 119.780111, "max_long": 119.783670
        },

        {
            "name": "FC_2",
            "min_lat": -23.554883, "max_lat": -23.548437,
            "min_long": 119.779436, "max_long": 119.783890
        },

        {
            "name": "FC_3",
            "min_lat": -23.547365, "max_lat": -23.546721,
            "min_long": 119.780265, "max_long": 119.787711
        },

        {
            "name": "FC_4",
            "min_lat": -23.545034, "max_lat": -23.541936,
            "min_long": 119.778426, "max_long": 119.780985
        },

        {
            "name": "FC_5",
            "min_lat": -23.542271, "max_lat": -23.541061,
            "min_long": 119.785279, "max_long": 119.786792
        },

        {
            "name": "FC_6",
            "min_lat": -23.554190, "max_lat": -23.548750,
            "min_long": 119.781730, "max_long": 119.784278
        },

        {
            "name": "FC_7",
            "min_lat": -23.554154, "max_lat": -23.527714,
            "min_long": 119.816292, "max_long": 119.826441
        },

        {
            "name": "FC_8",
            "min_lat": -23.408445, "max_lat": -23.378432,
            "min_long": 119.845858, "max_long": 119.861592
        },

        {
            "name": "FC_9",
            "min_lat": -23.528043, "max_lat": -23.409688,
            "min_long": 119.836652, "max_long": 119.861392
        },

        {
            "name": "FC_10",
            "min_lat": -23.544534, "max_lat": -23.530254,
            "min_long": 119.829564, "max_long": 119.855626
        },

        {
            "name": "FC_11",
            "min_lat": -23.563185, "max_lat": -23.549400,
            "min_long": 119.831683, "max_long": 119.850397
        },

        {
            "name": "FC_12",
            "min_lat": -23.371014, "max_lat": -23.344655,
            "min_long": 120.399275, "max_long": 120.416976
        },

        {
            "name": "FC_13",
            "min_lat": -23.419757, "max_lat": -23.415191,
            "min_long": 120.621927, "max_long": 120.639129
        },

        {
            "name": "FC_14",
            "min_lat": -23.454154, "max_lat": -23.446579,
            "min_long": 120.669888, "max_long": 120.694173
        },

        {
            "name": "FC_15",
            "min_lat": -22.777058, "max_lat": -22.775067,
            "min_long": 120.426475, "max_long": 120.434228
        }
        # Add as many patches as you need here...
    ]

    all_random_spots = []

    # The density dial: How many screenshots do you want per square kilometer?
    # Increase this number for more images, decrease it for fewer.
    DENSITY_PER_SQ_KM = 5

    print("Calculating area and generating random coordinates...")

    # 2. CALCULATE PROPORTIONAL SHOTS AND GENERATE COORDS
    for zone in fairy_circle_zones:
        # Figure out how many shots this patch gets based on its physical size
        proportional_count = calculate_shot_count(
            zone["min_lat"], zone["max_lat"],
            zone["min_long"], zone["max_long"],
            shots_per_sq_km=DENSITY_PER_SQ_KM
        )

        print(f" -> {zone['name']} gets {proportional_count} screenshots.")

        # Generate the random spots
        spots = generate_random_coords(
            zone_name=zone["name"],
            min_lat=zone["min_lat"], max_lat=zone["max_lat"],
            min_long=zone["min_long"], max_long=zone["max_long"],
            count=proportional_count
        )

        all_random_spots.extend(spots)

    print(f"\nTotal screenshots to take across all zones: {len(all_random_spots)}")
    print("Starting map generation...\n")

    # 3. TAKE ALL THE SCREENSHOTS
    take_specific_screenshots(
        coordinate_list=all_random_spots,
        sleep_time=1.6  # Seconds to wait for UI to hide before snapping
    )

