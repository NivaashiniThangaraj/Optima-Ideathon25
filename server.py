from flask import Flask, request, jsonify
from flask_cors import CORS
from CODE import run_pipeline  # This is your provided ML code
import tempfile
import os

app = Flask(__name__)
CORS(app)  # Allow cross-origin requests from Flutter

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    image_file = request.files['image']

    # Save the image temporarily
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
            tmp_path = tmp.name
            image_file.save(tmp_path)

        # Run the pipeline AFTER the file is saved and closed
        areas, materials = run_pipeline(tmp_path)

        return jsonify({**areas, **materials})

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Prediction failed: {str(e)}'}), 500

    finally:
        if tmp_path and os.path.exists(tmp_path):
            try:
                os.remove(tmp_path)
            except Exception as cleanup_error:
                print(f"⚠️ Could not delete temp file: {cleanup_error}")


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
