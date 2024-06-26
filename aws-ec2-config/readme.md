

# 3 Setup

## 3.1 Connect to SSH

- Using the private key generated in the previous step

open a bash terminal : 

```
mv kestra_key kestra_key.pem
chmod 400 kestra_key
ssh -i "kestra_key" ubuntu@"ec2-XX-XXX-XXX-XXX.eu-south-1.compute.amazonaws.com
```

## 3.2 Install Docker

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
sudo apt install docker-compose

```

## 3.3 Update 'docker-compose.yml' file

- Download the basic docker-compose file

```
curl -o docker-compose.yml https://raw.githubusercontent.com/kestra-io/kestra/develop/docker-compose.yml
cat docker-compose.yml
nano docker-compose.yml
```

Make change in order to match the docker-compose.yml file:

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

For simplicity I do not create a dedicate RDS instance but I use the local postgres service provided by the docker-compose file.

- Enviroment Variable Configuration

```  
kestra:
    image: kestra/kestra:latest-full
    env_file:
      - .env_encoded
```

## 3.4 Setup Kaggle Auth

In order to fetch the dataset using the Kaggle Public API we need the auth .json file:
- Just click on the generate token button at your [kaggle profile page](https://www.kaggle.com/settings/account)

## 3.5 Setup Redshift Istance

Make sure to setup the Redshift Cluster, I used the Serverless Redshift Service (that give you 300$ as free credit)

> Do not setup the redshift istance you don't have a free credit

I used this tutorial https://medium.com/@parkashpant1989/use-dbt-core-with-amazon-redshift-59dd29ce515f in order to setup my redshift istance.
The IAM role env variable refer to the default IAM role defined in the tutorial.

## 3.6 Setup Secrets

- Create a .env file with `nano .env` and set credentials from kaggle.json file:

```
KAGGLE_USERNAME=XXXXXXXX
KAGGLE_KEY=XXXXXXXX
AWS_ACCESS_KEY=XXXXXXXX
AWS_SECRET_KEY=XXXXXXXX
AWS_REGION=XXXXXXXX
REDSHIFT_USER=XXXXXXXX
REDSHIFT_PASSWORD=XXXXXXXX
REDSHIFT_HOST=XXXXXXXX
REDSHIFT_JDBC=XXXXXXXX
IAM_ROLE=XXXXXXXX
t=t # fake workaround var
```

run the following snippet in order to encode the .env file

```bash
while IFS='=' read -r key value; do
    echo "SECRET_$key=$(echo -n "$value" | base64)";
done < .env > .env_encoded
```