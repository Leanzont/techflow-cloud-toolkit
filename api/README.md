# API

Containerized Flask API for the TechFlow Cloud Toolkit.

## Structure

```
api/
├── app.py              # Flask application (health, data, drift endpoints)
├── Dockerfile          # Multi-stage container image
├── requirements.txt    # Python dependencies
└── README.md           # This file
```

## Endpoints

| Method | Path      | Description                                                 |
| ------ | --------- | ----------------------------------------------------------- |
| GET    | `/health` | Health check — returns service status                       |
| POST   | `/data`   | Accepts JSON data and stores it in memory                   |
| GET    | `/data`   | Retrieves all stored data with count                        |
| GET    | `/drift`  | Runs drift detector and returns infrastructure audit report |

## Local Development

### Without Docker

```bash
cd api/
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python app.py
```

The API will be available at `http://localhost:5000`.

### With Docker

Build from the **repository root** (required to access `tools/drift_detector/`):

```bash
cd ..
docker build -f api/Dockerfile -t techflow-api .
docker run -p 5000:5000 \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION=us-east-2 \
  techflow-api
```

The API will be available at `http://localhost:5000`.

## Usage Examples

### Health check

```bash
curl http://localhost:5000/health
```

Response:
```json
{"status": "ok", "service": "TechFlow API"}
```

### Store data

```bash
curl -X POST http://localhost:5000/data \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "value": 42}'
```

### Get drift report

```bash
curl http://localhost:5000/drift
```

Response:
```json
{
  "ec2": [{"name": "...", "state": "running", "match": true}],
  "rds": [{"name": "...", "state": "available", "match": true}],
  "s3": [{"name": "...", "state": "exists", "match": true}]
}
```

## Notes

- `/data` stores data **in memory** (`data_store` list). Data resets when the container restarts.
- `/drift` requires AWS credentials. In local Docker, pass them as environment variables. In production (ECS/EC2), the app uses IAM Roles automatically.
- Future improvement: connect `/data` to the RDS PostgreSQL instance for persistent storage.
