import os
import sys
from flask import Flask, request, jsonify

app = Flask(__name__)

# Buscar drift_detector en tools/ (funciona local y en Docker)
current_dir = os.path.dirname(os.path.abspath(__file__))
possible_paths = [
    os.path.join(current_dir, 'tools', 'drift_detector'),      # Docker
    os.path.join(current_dir, '..', 'tools', 'drift_detector')  # Local
]

drift_path = None
for path in possible_paths:
    if os.path.exists(os.path.join(path, 'drift_detector.py')):
        drift_path = path
        break

if drift_path:
    sys.path.insert(0, drift_path)
    from drift_detector import generate_report
else:
    generate_report = None

# Datos en memoria (endpoints originales)
data_store = []

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "TechFlow API"}), 200

@app.route("/data", methods=["POST"])
def post_data():
    body = request.get_json()
    if not body:
        return jsonify({"error": "no data provided"}), 400
    data_store.append(body)
    return jsonify({"message": "data saved", "data": body}), 201

@app.route("/data", methods=["GET"])
def get_data():
    return jsonify({"count": len(data_store), "data": data_store}), 200

@app.route("/drift", methods=["GET"])
def get_drift():
    if generate_report is None:
        return jsonify({"error": "drift detector not found"}), 500
    
    try:
        config_path = os.path.join(drift_path, 'expected.yaml')
        report = generate_report(config_path)
        return jsonify(report), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
# CI test
