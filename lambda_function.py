import json
import boto3
import os
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
sns = boto3.client('sns')

TABLE_NAME = os.environ['DYNAMODB_TABLE']
TOPIC_ARN = os.environ['SNS_TOPIC_ARN']

def lambda_handler(event, context):
    try:
        if 'body' in event:
            payload = json.loads(event['body'])
        else:
            payload = event 

        host_id = payload.get('host_id')
        cpu_usage = float(payload.get('cpu_usage', 0))
        memory_usage = float(payload.get('memory_usage', 0))
        timestamp = payload.get('timestamp', datetime.utcnow().isoformat())

        print(f"Received metrics from {host_id}: CPU {cpu_usage}%")

        table = dynamodb.Table(TABLE_NAME)
        table.put_item(
            Item={
                'host_id': host_id,
                'timestamp': timestamp,
                'cpu_usage': str(cpu_usage),     
                'memory_usage': str(memory_usage)
            }
        )

        if cpu_usage > 80.0:
            print(f"ALARM: CPU is {cpu_usage}%! Sending alert...")
            message = f"CRITICAL ALERT: {host_id} is experiencing high CPU load ({cpu_usage}%)."
            
            sns.publish(
                TopicArn=TOPIC_ARN,
                Message=message,
                Subject="Serverless Monitor Alert"
            )
            return {
                'statusCode': 200,
                'body': json.dumps('Metric saved & Alert sent!')
            }

        return {
            'statusCode': 200,
            'body': json.dumps('Metric saved successfully.')
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f"Internal Error: {str(e)}")
        }