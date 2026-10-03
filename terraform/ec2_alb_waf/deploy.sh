#!/bin/bash

echo "Default region is set to us-west-2"

# Step 1: Set AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"


# Initialize Terraform
tofu -chdir=terraform/ init -lock=false

# Apply tofu configuration
tofu -chdir=terraform/ apply -auto-approve -lock=false

# Save output to a file
tofu -chdir=terraform/ output -json > terraform_waf_output.json

# Create flag.txt
FLAG="peachycloudsecurity_flag_$(openssl rand -hex 12)"
sed -i "s|echo \"FLAG=.*|echo \"FLAG=$FLAG\" > /opt/flag.txt|" terraform/modules/ec2/main.tf 
echo "$FLAG" > flag.txt

# Show final message
echo "Deployment Complete"