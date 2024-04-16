# Deploy Kestra on AWS

# 1) Introduction




# 2) Infrastructure Deployment 

terraform : https://github.com/kestra-io/terraform-deployments/tree/main/aws-ec2
manual : https://kestra.io/docs/installation/aws-ec2


Requirements:
- AWS CLI installed with proper user configure 
- Clone this repo and open the terminal

## 2.1 Terraform Template

I created a terraform project folder starting from the official template:
 
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

In the ./aws-ec2 folder you can find a modified version of original template, the main differences are:
- auto generate ssh key
- same aws_istance resource without provisioner and user_data
- no dedicated rds istance

## 2.2 Deploy terraform project

> Note: the current version of this configuration assumes that you already have an IAM user roles with the corresponding policies to provisione AWS resources.

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

## 2.3 Destroy Terraform Resources
When you want:
```
terraform destroy -var-file="secrets.tfvars"
```

## 2.4 Connect to SSH

- Using the private key generated in the previous step

open a bash terminal : 

```
mv kestra_key kestra_key.pem
chmod 400 kestra_key
ssh -i "kestra_key" ubuntu@"ec2-XX-XXX-XXX-XXX.eu-south-1.compute.amazonaws.com
```


## 2.5 Install Docker

```
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

chmod +x install_docker

./install_docker

sudo docker version
```

## 2.6 Run Docker Compose 

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

For simplicity I do not create a rds instance but I use the local postgres service provided by the docker-compose file.

# 3) Setup Kestra

## 3.1 Setup Kaggle Auth

In order to fetch the dataset using the Kaggle Public API we need the auth .json file:
- Just click on the generate token button at your [kaggle profile page](https://www.kaggle.com/settings/account)
- Move the downloaded json file in the folder ./kestra_prod/config/kaggle.json

In order to sync the Deployed Kestra Istance with our repo, the simplest way is with [git.Sync](https://kestra.io/plugins/plugin-git/tasks/io.kestra.plugin.git.sync)

Create your first Kestra Flow, just copy-paste the following code in the UI editor :

```yaml
id: sync_from_git
namespace: prod

tasks:
  - id: git
    type: io.kestra.plugin.git.Sync
    url: https://github.com/simonefrisco/data-engineering-zoomcamp-final-project
    branch: main
    gitDirectory: kestra_prod # optional, otherwise all files
    namespaceFilesDirectory: prod # optional, otherwise the namespace root directory
    dryRun: true  # if true, print the output of what files will be added/modified or deleted without overwriting the files yet

triggers:
  - id: every_day
    type: io.kestra.core.models.triggers.types.Schedule
    cron: "0 0 */1 * *"
```
