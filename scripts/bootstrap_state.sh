#!/usr/bin/env bash
# One-time creation of the remote Terraform backend (S3 + DynamoDB lock).
set -euo pipefail
BUCKET="${1:?unique bucket name}"; REGION="${2:-us-east-1}"
aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" $( [ "$REGION" != us-east-1 ] && echo --create-bucket-configuration LocationConstraint=$REGION )
aws s3api put-bucket-versioning --bucket "$BUCKET" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws dynamodb create-table --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region "$REGION"
echo "Now uncomment the backend block in terraform/versions.tf"
