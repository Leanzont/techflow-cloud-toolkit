# Drift Detector 🔍

Python tool that detects infrastructure drift between a desired state 
(YAML configuration) and live AWS resources (EC2, S3, RDS).

---

## 🎯 What it does

1. Reads `expected.yaml` — the desired infrastructure state.
2. Queries AWS APIs in real time using `boto3`.
3. Normalizes both datasets into comparable dictionaries.
4. Compares expected vs. actual and reports:
   - ✅ **In sync**: Resource exists and matches expected state
   - ⚠️ **Missing**: Expected resource not found in AWS
   - ⚠️ **Unexpected**: Resource exists in AWS but is not declared in config (true drift)
5. Outputs a clear terminal report + structured JSON for audit trails.

---

## 🏗 Architecture


```
┌────────┐     ┌─────────┐       ┌─────────┐
│ expected.yaml  │ ─→│ drift_detector.py│←── │ AWS APIs         │
│ (desired)      │     │                  │       │ (EC2, S3, RDS)   │
└────────┘     └─────────┘       └─────────┘
                              │
                              ↓
                    ┌────────┐
                    │  Normalization │  ← Both sources → same dict structure
                    │   (dict logic) │
                    └────────┘
                             ↓
                    ┌────────┐
                    │   Comparison   │  ← Set operations: missing / extra / changed
                    │   (diff engine)│
                    └────────┘
                             ↓
                    ┌────────┐
                    │  Console + JSON│  ← Human readable + machine parseable
                    │    Output      │
                    └────────┘
```


---

## 📁 Project Structure

```
tools/drift_detector/
├── drift_detector.py      # Main script
├── expected.yaml          # Desired state configuration
├── requirements.txt       # Python dependencies
├── drift_report.json      # Generated report (ignored by git)
└── README.md              # This file
```

---

## 🚀 Usage

```bash
# Default: reads expected.yaml, outputs drift_report.json
python drift_detector.py

# Custom config and output paths
python drift_detector.py --config prod_baseline.yaml --output prod_report.json
```

---

## 📋 expected.yaml Example

```yaml
ec2:
  - name: "techflow-cloud-toolkit-ec2-instance-ec2-instance-techflow"
    expected_state: "running"

s3:
  - name: "techflow-logs-leandro2026"
    expected: "exists"
  - name: "techflow-backups-leandro2026"
    expected: "exists"

rds:
  - name: "techflow-cloud-toolkit-rds-postgressql"
    expected_state: "available"
```

---

## 📊 Output Examples

### No drift detected

```text
=== TechFlow Drift Detector ===

Service: EC2
Name: techflow-cloud-toolkit-ec2-instance-ec2-instance-techflow, state: running --> ✅

Service: RDS
Name: techflow-cloud-toolkit-rds-postgressql, state: available --> ✅

Service: S3
Name: techflow-logs-leandro2026, state: exists --> ✅
Name: techflow-backups-leandro2026, state: exists --> ✅
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
not drift detected
save local in --> drift_report.json
```

### Drift detected (unexpected resources)

```text
=== TechFlow Drift Detector ===

Service: EC2
Name: techflow-cloud-toolkit-ec2-instance-ec2-instance-techflow, state: running --> ✅
Name: ec2-instance-2, state: running --> ⚠️
Name: ec2-instance-1, state: running --> ⚠️

Service: RDS
Name: techflow-cloud-toolkit-rds-postgressql, state: available --> ✅
Name: mi-rds-drift-test, state: deleting --> ⚠️

Service: S3
Name: techflow-logs-leandro2026, state: exists --> ✅
Name: techflow-backups-leandro2026, state: exists --> ✅
Name: lean-23, state: exists --> ⚠️
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
drift detected: 4 resource(s)
save local in --> drift_report.json
```

### JSON Report (with drift)

```json
{
    "ec2": [
        {
            "name": "techflow-cloud-toolkit-ec2-instance-ec2-instance-techflow",
            "state": "running",
            "match": true
        },
        {
            "name": "ec2-instance-2",
            "state": "running",
            "match": false,
            "drift_type": "unexpected"
        },
        {
            "name": "ec2-instance-1",
            "state": "running",
            "match": false,
            "drift_type": "unexpected"
        }
    ],
    "rds": [
        {
            "name": "techflow-cloud-toolkit-rds-postgressql",
            "state": "available",
            "match": true
        },
        {
            "name": "mi-rds-drift-test",
            "state": "deleting",
            "match": false,
            "drift_type": "unexpected"
        }
    ],
    "s3": [
        {
            "name": "techflow-logs-leandro2026",
            "state": "exists",
            "match": true
        },
        {
            "name": "techflow-backups-leandro2026",
            "state": "exists",
            "match": true
        },
        {
            "name": "lean-23",
            "state": "exists",
            "match": false,
            "drift_type": "unexpected"
        }
    ]
}
```

---

## 🧠 What I Learned Building This

### v1 — First Attempt

I started with nested `for` loops that iterated AWS responses directly, mixing data extraction with comparison logic. This caused several problems:

- **Overwriting data:** I stored instance names in a dictionary with fixed keys (`'name'` and `'state'`), so each new instance overwrote the previous one.
- **Wrong comparisons:** I used substring matching (`in` instead of `==`) and checked conditions before collecting all AWS data.
- **Premature returns:** My EC2 function returned `"not found"` on the first non-matching tag, without checking remaining instances.

### v2 — Refactored Approach

I separated the process into four distinct layers:

1. **Extraction** — Pull raw data from AWS APIs (EC2, RDS, S3)
2. **Normalization** — Convert both AWS responses and `expected.yaml` into identical dictionary structures (`{resource_name: state}`)
3. **Comparison** — Iterate over expected resources and check existence/state against the normalized AWS dictionary
4. **Output** — Generate a unified report with icons, drift count, and JSON export

**Why it matters:** Each layer is independent. If AWS changes an API response format, I only update the extraction layer. The comparison logic stays untouched.

### Other Functions

- **`print_show_info()`** — Uses `.items()` to iterate over the report dictionary service by service, printing status with ✅/⚠️ icons and calculating the final drift count.
- **`save_local()`** — Exports the report to JSON for audit trails or CI/CD integration.
- **`main()`** — Orchestrates the flow: reads config, runs each detector, prints results, and saves output.

### Unexpected Resource Detection

My first attempt at detecting unexpected resources used nested loops over the AWS dictionary with `.items()`. It was messy and inefficient.

I refactored it using **set operations**:

```python
expected_names = {e['name'] for e in expected_config['ec2']}
aws_names = set(aws_instances.keys())
unexpected = aws_names - expected_names
```

This leverages Python's set difference to find resources that exist in AWS but are not declared in the config. I then applied the same logic to RDS and S3.

### Key Insight

> Drift detection is not about iterating APIs. It's about creating a **common data model** for two different sources, then doing set operations on them.

---

## 🛠 Prerequisites

- Python 3.10+
- AWS credentials configured (`aws configure` or environment variables)
- `boto3`, `pyyaml`

```bash
pip install -r requirements.txt
```

---

## 📦 requirements.txt

```text
boto3>=1.34.0
pyyaml>=6.0
```

---

## 🔮 Future Improvements

- [ ] Add retry logic with exponential backoff for AWS API throttling
- [ ] Support multiple regions (currently hardcoded to `us-east-2`)
- [ ] Add drift detection for IAM policies and Security Group rules
- [ ] Integrate with GitHub Actions for scheduled audits
- [ ] Add email/Slack notifications when drift is detected

