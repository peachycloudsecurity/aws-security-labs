#!/bin/bash

echo "Starting destruction process..."

# Step 1: Set AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"

# Destroy tofu resources in the order they were created

# Destroy tofu resources
echo "Destroying tofu resources..."
# Apply tofu configuration
tofu -chdir=terraform/ destroy -auto-approve -lock=false



# Step 5: Delete additional files and directories
echo "Deleting additional files and directories..."
rm -rf terraform/.tofu \
       terraform/terraform.tfstate \
       terraform/terraform.tfstate.backup \
       terraform/.terraform.lock.hcl \
       terraform_waf_output.json \
       flag.txt

#update flag placeholder
sed -i 's|echo "FLAG=.*"|echo "FLAG=flagplaceholder" > /opt/flag.txt|' terraform/modules/ec2/main.tf

echo "Destruction process complete."
