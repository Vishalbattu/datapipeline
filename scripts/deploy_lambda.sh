#!/bin/bash

# Navigate to the lambda directory
cd lambda/

# Install dependencies into a local package folder
pip install -r requirements.txt -t ./package

# Zip up the Lambda function and its dependencies
cd package && zip -r ../lambda.zip . && cd ..
zip -g lambda.zip lambda_function.py

# Deploy the Lambda function to AWS
aws lambda update-function-code --function-name file-processor --zip-file fileb://lambda.zip
