# custom_vpc

Provision AWS resources via Terraform. Create a VPC with 3 public and 3 private subnets across multiple AZs.
Spin up a EC2 instance with Nginx on port 80 and make it reachable over HTTP by IP.

Create:
 - VPC with CIDR block 10.50.0.0/16
 - 3 private subnets across different AZs within the VPC
 - 3 public subnets across different AZs within the VPC
 - Ensure EC2 instances in public subnet have internet access
 - Ensure EC2 instances in private subnet don't have a direct internet access
 - Parametrize Terraform code for reusability and flexibility
 - Ensure you have meaningful commit messages
 - Code should not contain any comments


