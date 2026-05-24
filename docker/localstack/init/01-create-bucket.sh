#!/bin/bash
set -e

awslocal s3 mb s3://shelfie-local || true
awslocal s3api put-bucket-policy --bucket shelfie-local --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::shelfie-local/*"
  }]
}'
