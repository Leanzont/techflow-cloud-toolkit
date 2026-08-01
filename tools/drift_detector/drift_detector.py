import json
import yaml
import argparse
import boto3

def file_yaml(file_yaml="expected.yaml"):
    with open(file_yaml, "r") as f:
        return yaml.safe_load(f)

def ec2(expected_config):
    ec2 = boto3.client("ec2", region_name="us-east-2")
    response = ec2.describe_instances()
    aws_instances = {}
    results = []
   
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            for tag in instance.get('Tags', []):
                if tag['Key'] == 'Name':
                    aws_instances[tag['Value']] = instance['State']['Name'] 
    for expected in expected_config['ec2']:
        expected_name  = expected['name']
        expected_state = expected['expected_state']

        if expected_name in aws_instances:
            actual_state = aws_instances[expected_name] 
            match = (actual_state == expected_state)

            results.append ({
                "name": expected_name,
                "state": actual_state,
                "match": match
                                           })
        else:
            results.append({
                "name": expected_name,
                "state": "not found",
                "match": False
         })

    expected_names = {e['name']for e in expected_config['ec2']}
    aws_names = set(aws_instances.keys())
    unexpected = aws_names - expected_names
   
    for i in unexpected:
        unexpected_state = aws_instances[i]
        results.append ({
            "name": i,
            "state": unexpected_state,
            "match": False,
            "drift_type": "unexpected"
            })
    return results

def rds(expected_config):
    rds = boto3.client("rds", region_name="us-east-2")
    response = rds.describe_db_instances()
    results = []
    aws_rds = {}

    for instances_db in response['DBInstances']:
        aws_rds[instances_db['DBInstanceIdentifier']] = instances_db['DBInstanceStatus']
     
    
    for expected in expected_config['rds']:
        expected_name = expected['name']
        expected_state = expected['expected_state']

        if expected_name in aws_rds:
            actual_state = aws_rds[expected_name]
            match = (expected_state == actual_state)
            results.append({
                "name": expected_name,
                "state": actual_state,
                "match": match
                })
        else:
            results.append({
                "name": expected_name,
                "state": "not found",
                "match": False
                })
    expected_names = {e['name']for e in expected_config['rds']}
    names_rds = set(aws_rds.keys())
    unexpected = names_rds - expected_names
    for u in unexpected:
        unexpected_state = aws_rds[u]
        results.append({
            "name": u,
            "state": unexpected_state,
            "match": False,
            "drift_type": "unexpected"
            })
    return results

def s3(expected_config):
    s3 = boto3.client("s3", region_name="us-east-2")
    response = s3.list_buckets()
    data_s3 = []

    aws_buckets = {i['Name']for i in response['Buckets']} 

    for expected in expected_config.get("s3", []): 
        bucket_name = expected["name"] 
        
        if bucket_name in aws_buckets:
            data_s3.append({
                "name": bucket_name,
                "state": "exists",
                "match": True
            })
        else:
            data_s3.append({
                "name": bucket_name,
                "state": "missing",
                "match": False
            })
    expected_bucket_name = {n['name']for n in expected_config['s3']}

    unexpected_bucket = aws_buckets - expected_bucket_name
    for e in unexpected_bucket: 
        data_s3.append({
            "name": e,
            "state": "exists",
            "match": False,
            "drift_type": "unexpected"  
            })
    return data_s3

def print_show_info(report):
    drift_count = 0 

    print("\n=== TechFlow Drift Detector ===\n")
    for key, value in report.items(): 
        print(f"\nService: {key.upper()}")

        for r in value:
            if not r['match']:
                drift_count += 1 
            icon = "✅" if r['match'] == True else "⚠️"
            print(f"Name: {r['name']}, state: {r['state']} --> {icon}")
    print("~" * 50)
    print("not drift detected" if drift_count == 0 else f"drift detected: {drift_count} resource(s)")
            
def save_local(report, file="drift_report.json"):
    with open(file, "w") as f:
        json.dump(report, f, indent=4)
    return f"save local in --> {file}\n"
            

def main():
    parser = argparse.ArgumentParser(description="TechFlow Drift Detector")
    parser.add_argument("--config", default="expected.yaml")
    parser.add_argument("--output", default="drift_report.json")
    args = parser.parse_args()

    config = file_yaml(args.config)
    report = {}
    if "ec2" in config:
        report['ec2'] = ec2(config)
    if "rds" in config:
        report['rds'] = rds(config)
    if "s3" in config:
        report['s3'] = s3(config)
    
    
    print_show_info(report)
    print(save_local(report, args.output))

if __name__ == "__main__":
    main()


