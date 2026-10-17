import os
import sys
import json
import boto3
import psycopg2
from flask import Flask, request, jsonify

app = Flask(__name__)

# ── Drift detector path ──────────────────────────────────────────────
current_dir = os.path.dirname(os.path.abspath(__file__))
possible_paths = [
    os.path.join(current_dir, 'tools', 'drift_detector'),
    os.path.join(current_dir, '..', 'tools', 'drift_detector')
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


# ── Database connection ──────────────────────────────────────────────
def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ["DB_HOST"],
        port=os.environ["DB_PORT"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASS"]
    )
    return conn


def init_db():
    """Create the data_entries table if it does not exist."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS data_entries (
                id    SERIAL PRIMARY KEY,
                data  JSONB NOT NULL
            );
        """)
        conn.commit()
        cur.close()
        conn.close()
        print("Database initialized successfully")
    except Exception as e:
        print(f"Database init failed: {e}")


# ── Endpoints ────────────────────────────────────────────────────────
@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "TechFlow API"}), 200


@app.route("/data", methods=["POST"])
def post_data():
    body = request.get_json()
    if not body:
        return jsonify({"error": "no data provided"}), 400

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO data_entries (data) VALUES (%s)", [json.dumps(body)])
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({"message": "data saved", "data": body}), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/data", methods=["GET"])
def get_data():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT data FROM data_entries ORDER BY id ASC")
        rows = [row[0] for row in cur.fetchall()]
        cur.close()
        conn.close()
        return jsonify({"count": len(rows), "data": rows}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500


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
    init_db()
    app.run(host="0.0.0.0", port=5000)
