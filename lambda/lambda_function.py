import boto3
import os
import mimetypes

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get the bucket and file details from the event
    for record in event['Records']:
        source_bucket = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']

        # Determine the destination bucket based on file suffix (
        if "_records" in file_key:
            destination_bucket = os.environ['RECORD_BUCKET']
        elif "_tokens" in file_key:
            destination_bucket = os.environ['TOKEN_BUCKET']
        else:
            print(f"File {file_key} does not match _records or _tokens suffix. Skipping.")
            return
        
        # Download the file from the source bucket
        tmp_file_path = f'/tmp/{file_key}'
        s3.download_file(source_bucket, file_key, tmp_file_path)
        
        # Determine the file format based on MIME type or extension 
        mime_type, _ = mimetypes.guess_type(tmp_file_path)
        if mime_type == 'text/csv':
            format_suffix = 'csv'
        elif mime_type == 'application/x-parquet':
            format_suffix = 'parquet'
        else:
            print(f"Unrecognized format for file {file_key}. Skipping.")
            return
        
        # Append format to the file name (e.g., 20240101_records.csv)
        new_file_key = file_key.replace('_records', f'_records.{format_suffix}').replace('_tokens', f'_tokens.{format_suffix}')
        
        # Upload the file to the destination bucket
        s3.upload_file(tmp_file_path, destination_bucket, new_file_key)
    
