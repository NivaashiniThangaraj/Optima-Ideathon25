import re
from PIL import Image, ImageOps
import pandas as pd
import joblib
import os
import pytesseract
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# === 1. Load your trained model ===
MODEL_PATH = "material_predictor_model.pkl"
model = joblib.load(MODEL_PATH)

# === 2. OCR helper ===
def extract_text_from_image(image_path):
    img = Image.open(image_path).convert("L")
    img = ImageOps.expand(img, border=20, fill="white")
    text = pytesseract.image_to_string(img)
    return text.lower().replace("\n", " ")

# === 3. Flexible area extractor with threshold ===
def extract_total_area(text, min_area=100):
    # Extended pattern to include all possible variants
    pattern = r"(\d{1,3}(?:,\d{3})*(?:\.\d+)?|\d+)\s*(?:sq\.?\s*ft|sqft|sq\s*ft|sft|sqft\.?|square\s*feet|sq,ft|Sq\.?ft|SFT|SQ\.?FT|SQFT|SQ\s*FT|Sq\s*ft)"
    matches = list(re.finditer(pattern, text, re.IGNORECASE))

    areas = []
    for match in matches:
        value = match.group(1).replace(",", "")
        try:
            num = float(value)
            # Context window (30 characters before and after)
            context = text[max(0, match.start() - 30):match.end() + 30]
            if "plot" in context.lower():
                print(f"🚫 Skipping value near 'plot': {num}")
                continue
            if num >= min_area:
                areas.append(num)
        except:
            continue

    total = sum(areas)
    print(f"📊 Extracted valid areas: {areas} → Total = {total} sq.ft")
    return total




# === 4. Floor logic: multiply area by number of floors ===
def analyze_blueprint_text(text):
    total = extract_total_area(text)
    ground = first = second = 0.0

    has_ground = "ground floor" in text
    has_first  = "first floor" in text
    has_second = "second floor" in text

    is_total_buildup = any(
        keyword in text
        for keyword in ["builtup area", "build up area", "built-up area", "building area", "construction area", "godown", "g.f.building"]
    )

    # NEW LOGIC: If both ground + first floor exist but only one sq.ft value — treat it as for both
    if total > 0 and has_ground and has_first:
        print("🧠 Detected shared sq.ft value for ground + first floor → duplicating area")
        ground = total
        first = total
    elif is_total_buildup and not (has_ground or has_first or has_second):
        ground = total  # Default if generic build-up label found
    elif not any([has_ground, has_first, has_second]):
        ground = total  # Default single-floor assumption
    else:
        if has_ground:
            ground = total
        if has_first:
            first = ground if "same as ground" in text else total
        if has_second:
            second = ground if "same as ground" in text else total

    final_total = ground + first + second
    print(f"🗺 Floor areas → Ground: {ground}, First: {first}, Second: {second}, Total: {final_total}")
    return {
        "Ground floor": ground,
        "First floor": first,
        "Second floor": second,
        "total Area(sq.ft)": final_total
    }

# === 5. Material prediction wrapper ===
def predict_materials(area_dict):
    df_in = pd.DataFrame([area_dict])
    preds = model.predict(df_in)[0]
    labels = ['Cement (bags)', 'Bricks', 'Steel (kg)', 'Sand (cu.ft)', 'Stones (cu.ft)']
    return dict(zip(labels, preds.tolist()))

# === 6. Full pipeline ===
def run_pipeline(image_path):
    print(f"\n🔍 OCR on '{image_path}' …")
    text = extract_text_from_image(image_path)

    print("\n📐 Extracting & analyzing areas …")
    areas = analyze_blueprint_text(text)

    print("\n🔧 Predicting materials …")
    materials = predict_materials(areas)

    print("\n📦 Final Prediction:")
    for k,v in {**areas, **materials}.items():
        print(f"  {k:20} → {v:.2f}")
    return areas, materials

# === 7. Example usage ===
if __name__ == "__main__":
    img = input("🖼️ Enter the path to the blueprint image (.png or .jpg): ").strip()
    # remove any stray quotes
    img = img.strip('"').strip("'")
    # normalize backslashes so \b isn’t treated as backspace
    img = os.path.normpath(img)

    if not (img.lower().endswith(".png") or img.lower().endswith(".jpg") or img.lower().endswith(".jpeg")):
        print("❌ Error: Only .png and .jpg image formats are supported.")
    elif not os.path.exists(img):
        print(f"❌ Error: File not found at\n   {img}")
    else:
        run_pipeline(img)


