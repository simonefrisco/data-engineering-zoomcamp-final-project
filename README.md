# Deploy Kestra on AWS

1) Manual Deployment

source : https://kestra.io/docs/installation/aws-ec2

2) Terraform Deployment

source : https://github.com/kestra-io/terraform-deployments/tree/main/aws-ec2


# 2) Terraform Deployment 

Requirements:
- AWS CLI installed with proper user configure 

## 2.1 Clone the official starter template

Using Windows 
```
git clone https://github.com/kestra-io/terraform-deployments/
move .\terraform-deployments\aws-ec2 .\aws-ec2
rmdir /s /q .\terraform-deployments
```
At this point, following the readme istructions you have to :
1) create a secrets.tfvars file with the following variables:
```
db_username= "xxxx"
db_password= "xxxx"
my_ip= "xxxx"
aws_access_key= "xxxx"
aws_secret_key= "xxxx"
```
2) create the key piar
3) initialize the terraform directory and apply the config

! Attention, make sure to change the ami-xxxxxxx value based on your aws region

Sadly, I was able to deploy almost all resources tranne the webserver.

I think that the problem was in some of the docker configuration so I decided to deploy the webserver partially manually.


In the aws-ec2 folder of this repo you can find a modified version of the main.tf :
- auto generate ssh key
- same aws_istance resource without provisioner and user_data

## 2.2 Deploy terraform project

Make sure to set the proper aws profile and then run terraform commands:

```
set AWS_PROFILE=your-aws-cli-profile
terraform init
terraform apply -var-file="secrets.tfvars"
```

### Output of the Terraform Apply

```
Outputs:
web_public_dns = "ec2-XX-XXX-XXX-XXX.eu-south-1.compute.amazonaws.com"
web_public_ip = "XXX.XXX.XXX.XXX"
```

## Destroy Terraform Resources

When you want:
```
terraform destroy -var-file="secrets.tfvars"
```

## Connect to SSH

- Using the private key generated in the previous step

open a bash terminal : 

mv kestra_key kestra_key.pem
chmod 400 kestra_key
ssh -i "kestra_key" ubuntu@"ec2-XX-XXX-XXX-XXX.eu-south-1.compute.amazonaws.com

> Note: the current version of this configuration assumes that you already have an IAM user roles with the corresponding policies to provisione AWS resources.

## Install Docker

'''
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER

newgrp docker
'''

chmod +x install_docker

./install_docker

sudo docker version

## Run Docker Compose 

- Download the basic docker-compose file

```
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
cat docker-compose.yml
nano docker-compose.yml
```
make change in order to macth the docker-compose.yml file:

- Auth Configuration 

```yaml
        kestra:
          server:
            basic-auth:
              enabled: true
              username: "adminemailfor@datatalkclub.io"
              password: kestra_secret_pass
```

- Postgres Configuration

For simplicity I do not create a rds instance but I use the local postgres instance provided by the docker-compose file.