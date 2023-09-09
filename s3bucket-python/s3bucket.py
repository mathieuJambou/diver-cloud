import sys
"""Module aws SDK"""
import boto3

BUCKET_NAME = sys.argv[1]
REGION = sys.argv[2]

def main():
    ''' main class'''
    try:
        create_s3bucket(BUCKET_NAME, REGION)

    except Exception as exception:
        print(exception)

def create_s3bucket(bucket_name, region):
    '''create a s3 bucket in aws with region an name parameters'''
    s3_bucket = boto3.client(
        's3',
        region_name=region
    )

    # Formatting the LocationConstraint key-value pair the API is expecting
    # for CreateBucketConfiguration
    location = {'LocationConstraint': region}
    bucket = s3_bucket.create_bucket(
        Bucket=bucket_name,
        ACL='private',
        CreateBucketConfiguration=location
    )

    print(bucket)

if __name__ == '__main__':
    main()
