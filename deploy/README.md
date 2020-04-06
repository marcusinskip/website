# St Botolph's CMS application cloud delivery document

## Overview of the Terraform configuration

Variables are defined in the variables.tf file for the Environment, Availability Zones, Regions and VPC subnets and DJango environment.   
Amend these variables as required for new implementations.  The Terraform code will create the following resources:

- A number of private and public subnets (depending on the number of Availability Zones defined)  
- A PostgreSQL database (variables can be changed to change the version etc.), 
- NAT gateways in the public subnets to allow internet access outwards from the private subnets
- Fargate Elastic Container Service (increase the number of instances by changing the desired count variable)
- An Application Load Balancer (ALB) to load balance the AWS Fargate Elastic Container Service containers
- Internet Gateway for the public subnets
- Security Groups to allow access from Fargate container to RDS and ALB to Fargate container
- S3 bucket to store images
- SMTP configuration for AWS SES, Amazon's Simple Email Service
- Fargate container to run the database migration and create the super user

All deliverables are contained in the sub directory deploy

## Future enhancements

- Terraform configuration converted to Modules, thus allowing code reuse.
- Secret information stored in AWS Secret Manager or AWS SSM Parameter Store and a small application placed in the Docker container to obtain the secret information. 
- AWS Autoscaling group to scale up and down AWS Fargate resources depending on demand
- AWS Code pipeline to provide a build process and automatic deployment
- AWS Application Firewall to provide application level protection
- Route 53 to provide a suitable domain plan_name
- SSL Certificate to provide encryption of data in transit 
- Monitoring of resources including the database migration container to confirm it has run successfully
- Make Terraform more DRY using for_each loops

## Container image upload instructions

The Terraform code creates a AWS Elastic Container Registry (ECR) to store the container images.
Terraform will output the URL for the AWS ECR, this will be required to upload (push) the latest image.

1. Build the Docker image and tag the image

In the instructions replace <region> with the correct region defined in the Terraform variables.tf file as region and <amazon_account_id> with the appropriate account id.

2. Push the image to the AWS ECR, to manually push the image from the command line (aws cli must be installed with appropriate authentication keys) and login into AWS ECR as follows: 

aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <amazon_account_id>.dkr.ecr.<region>.amazonaws.com

4. Tag the docker image, for example:  

docker tag webapp:1 <amazon_account_id>.dkr.ecr.<region>.amazonaws.com/ecr_repo

5. Push the image:

docker push <amazon_account_id>.dkr.ecr.<region>.amazonaws.com/ecr_repo

6. Update the Terraform variables.tf file variable app_image_version with the version number generated during the tag step 4. 

7. Execute from the command line (amend the <plan_name> appropriately) : 

 terraform plan -o <plan_name>.tfplan
 terraform apply <plan_name>.tfplan

8. To deploy newer versions of the container image follow steps 1 to 7.

