#!/bin/bash
#
# Deploy Foo app - see README.md
#

set -e

echo "Running Section A deployment script"

echo "Testing AWS credentials"
aws sts get-caller-identity

path_to_ssh_key="~/.ssh/id_rsa"

cd misc
echo "Initializing Terraform for S3 Bucket"
terraform init

echo "Validating Terraform Configuration"
terraform validate

echo "Running terraorm apply"
terraform apply

cd..
cd infra

echo "Initializing Terraform"
terraform init

echo "Validating Terraform Configuration"
terraform validate

echo "Running terraform apply"
terraform apply

# Get the private IP address of the database
db_private_ip=$(terraform output -json vm_ip_addresses | jq -r '.db.private_ip_address')

# Get the public IP addresses of the app and db instances
app1_public_ip=$(terraform output -json vm_ip_addresses | jq -r '.app1.public_ip_address')
app2_public_ip=$(terraform output -json vm_ip_addresses | jq -r '.app2.public_ip_address')
db_public_ip=$(terraform output -json vm_ip_addresses | jq -r '.db.public_ip_address')

# Generate inventory1.yml for app servers
cat <<EOL > ../ansible/app1.yml
app1_servers:
  hosts:
    app1:
      ansible_host: '$app1_public_ip' # Fill in your "app" instance's public IP address here
EOL

cat <<EOL > ../ansible/app2.yml
app2_servers:
  hosts:
    app2:
      ansible_host: '$app2_public_ip' # Fill in your "app" instance's public IP address here
EOL

# Generate inventory2.yml for db servers
cat <<EOL > ../ansible/db.yml
db_servers:
  hosts:
    db1:
      ansible_host: '$db_public_ip' # Fill in your "db" instance's public IP address here
EOL

cd ..
cd ansible

# Run the Ansible playbooks
echo "Running Ansible playbook for the database"
ansible-playbook db-playbook.yml -i db.yml --private-key $path_to_ssh_key

echo "Running Ansible playbook for app1"
ansible-playbook app1-playbook.yml -i app1.yml --private-key $path_to_ssh_key --extra-vars "db_hostname=$db_private_ip"

echo "Running Ansible playbook for app2"
ansible-playbook app1-playbook.yml -i app1.yml --private-key $path_to_ssh_key --extra-vars "db_hostname=$db_private_ip"

echo "Deployment completed successfully!"