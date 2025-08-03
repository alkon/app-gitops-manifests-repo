# Lambda S3 Cleanup Setup Instructions

## Overview
This Lambda function monitors the `alkon-thanos-metrics-dev` S3 bucket size and automatically deletes all objects when the bucket exceeds 50MB.

## Setup Steps in AWS Console

### 1. Create IAM Role
1. Go to IAM → Roles → Create role
2. Select "Lambda" as the trusted entity
3. Create a custom policy with the following JSON:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::alkon-thanos-metrics-dev"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::alkon-thanos-metrics-dev/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:GetMetricStatistics"
            ],
            "Resource": "*"
        }
    ]
}
```

4. Name the role: `thanos-s3-cleanup-lambda-role`

### 2. Create Lambda Function
1. Go to Lambda → Create function
2. Choose "Author from scratch"
3. Function name: `thanos-s3-cleanup`
4. Runtime: Python 3.11
5. Architecture: x86_64
6. Execution role: Use existing role → Select `thanos-s3-cleanup-lambda-role`

### 3. Configure Lambda
1. Copy the code from `lambda-s3-cleanup.py` into the Lambda editor
2. Configuration → General configuration:
   - Memory: 256 MB
   - Timeout: 5 minutes
3. Save the function

### 4. Add CloudWatch Events Trigger
1. In Lambda function → Add trigger
2. Select "EventBridge (CloudWatch Events)"
3. Create a new rule:
   - Rule name: `thanos-s3-cleanup-schedule`
   - Rule type: Schedule expression
   - Schedule expression: `rate(1 hour)` (runs every hour)
4. Add the trigger

### 5. Test the Function
1. Create a test event with empty JSON: `{}`
2. Run the test
3. Check CloudWatch Logs for output

## How It Works
- The Lambda runs every hour
- It checks the bucket size using CloudWatch metrics
- If size > 50MB, it deletes all objects in the bucket
- CloudWatch metrics are updated once per day, so there may be a delay

## Monitoring
- Check CloudWatch Logs for Lambda execution logs
- Monitor Lambda metrics in CloudWatch
- Set up CloudWatch Alarms if needed

## Important Notes
- **WARNING**: This function deletes ALL objects when the limit is reached
- CloudWatch S3 metrics update once per day (around midnight UTC)
- The function uses the Average statistic from the last 24 hours
- Consider adjusting the schedule based on your data growth rate