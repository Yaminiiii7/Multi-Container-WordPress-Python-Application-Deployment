# Multi-Container WordPress & Python Application Deployment on AWS EC2 Using Terraform and Docker Compose

### 🛠️ Complete Deployment with Docker Compose: WordPress + MySQL + Python App

In this hands-on, you'll learn how to install, configure and run multiple services with **Docker Compose**, making it easier to manage multi-container applications.

### 🚀 What you'll do:

- Install **Docker Compose** in a Linux environment (with emphasis on EC2 Ubuntu 22.04, where it comes already installed).
- Create an environment consisting of:
    - A **MySQL** database
    - A WordPress site accessible via port `8080`
    - A Python application for uploading files, running on port `8081`
- Use **Docker volumes** to ensure data persistence
- Use a **customized Docker network** for communication between WordPress and MySQL
- Manage your services with commands such as `up`, `down`, `ps`, `start`, `stop`, `logs`, `pause` and `unpause`



---

####  AWS EC2 Instance Preparation**

1.  **Create User**
    * In the AWS console, Identity and Access Management --> Users --> Create User
    * Type terraform-User --> next.
    * Click on **Attach Policies directly**. Set permissions to **AmazonEC2FullAccess** and then create user.


    * Go to security credentials tab of user to create access key
    * Click on create access key and select Command Line Interface (CLI) option and create.
    * Open CLI, type **aws configure** and get credentials from AWS console.

    ```
        AWS Access Key ID:     <paste access key>
        AWS Secret Access Key: <paste secret key>
        Default region name:   us-west-2
        Default output format: json

    ```


2.  Create .pem file in AWS console as shown.

    <img src="diagrams/EC2_Keypair.png">

3.  Install Terraform through winget

    ```
        winget install HashiCorp.Terraform
        terraform -version

    ```
    Winget will download Terraform, installs it, add it to your PATH automatically.

#### Create main.tf file and add the following.
```
provider "aws" {
    region = "us-west-2"  
  }

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security group for wordpress,python and SSH"

  
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["23.241.194.129/32"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EC2-SG"
  }
}

resource "aws_instance" "ec2" {
  ami                    = "ami-00f46ccd1cbfb363e" # ubuntu server (Oregon)
  instance_type          = "c7i-flex.large"
  key_name               = "EC2_Keypair"         # .pem extension will be added auto
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = {
    Name = "Jenkins-Flask-EC2"
  }
}

```
5.  Create EC2 with following commands in the CLI.

    ```
        terraform init
        terraform plan
        terraform apply

    ```

---

 #### **Connect to EC2 Instance**
Use SSH to connect to the instance's public IP address.
```bash
        ssh -i /path/to/key.pem ubuntu@<ec2-public-ip>
```


 ####   **Update System Packages:**
```bash
        sudo apt update && sudo apt upgrade -y
```

 ####   **Install Git, Docker, and Docker Compose:**
```bash
        sudo apt install git docker.io docker-compose-v2 -y
```

 ####  **Start and Enable Docker:**
```bash
        sudo systemctl start docker
        sudo systemctl enable docker
```

 ####  **Add User to Docker Group (to run docker without sudo):**
```bash
        sudo usermod -aG docker $USER
        newgrp docker
```

 ####  **Clone the repository to EC2** 

```bash
        mkdir -p ~/DockerComposeProject
        cd ~/DockerComposeProject
        git clone https://github.com/Yaminiiii7/Multi-Container-WordPress-Python-Application-Deployment.git .

```


## Step 01 - Cleaning up the environment

```bash
docker ps
docker stop
docker ps -a

docker system prune -a -f --volumes

docker images
docker volume ls
docker volume rm <volume-name>
```

## Step 02 - Installing Docker Compose on Linux:

Follow the [official Docker Compose Installation Guide.](https://docs.docker.com/compose/install/linux/)

<aside>
💡

EC2 with Ubuntu 22.04 or higher, Docker Compose is already installed!

</aside>

```bash
docker compose version

# Docker Compose Installation Commands (Optional)
sudo apt-get update
sudo apt-get install docker-compose-plugin
```

## Step 03 - Creating a directory for Docker-Compose

```bash
mkdir docker-compose && cd docker-compose

# The same Python "Upload Application" Files
wget https://tcb-bootcamps.s3.amazonaws.com/tcb5001-devopscloud-bootcamp/v2/module5-docker/files/module5-docker.zip

unzip module5-docker.zip
cd handsontask/volumes

cat Dockerfile
cat requirements.txt  # Flask

touch docker-compose.yaml
```

## Step 04 - Docker Compose YAML file

📄 `docker-compose.yaml`

```yaml
version: '3'  # Docker Compose file format version

services:
  db-ctr:  # MySQL database container
    image: mysql:5.7  # Uses MySQL 5.7 image
    volumes:
      - db-vol:/var/lib/mysql  # Stores MySQL data in a named volume
    environment:
      MYSQL_ROOT_PASSWORD: wordpress  # Root user password
      MYSQL_DATABASE: wordpress       # Name of the default database
      MYSQL_USER: devopscloudbootcamp  # Database user
      MYSQL_PASSWORD: devopscloudbootcamp  # User's password
    networks:
      - wp-net  # Connects to the 'wp-net' custom network
    restart: always  # Automatically restarts if the container stops

  wp-ctr:  # WordPress web application
    image: wordpress:latest  # Uses the latest WordPress image
    ports:
      - "8080:80"  # Maps port 8080 on host to port 80 in the container
    environment:
      WORDPRESS_DB_HOST: db-ctr:3306  # Host and port of the MySQL service
      WORDPRESS_DB_USER: devopscloudbootcamp  # DB username
      WORDPRESS_DB_PASSWORD: devopscloudbootcamp  # DB password
      WORDPRESS_DB_NAME: wordpress  # WordPress DB name
    networks:
      - wp-net  # Connects to the same network as MySQL
    restart: always  # Auto-restart on failure or reboot
    depends_on:
      - db-ctr  # Ensures the database starts before WordPress

  py-upload-app-ctr:  # Custom Python upload application
    build:            # The image for this conteiner will not come from Docker Hub
      context: .  # Build context is the current directory
      dockerfile: Dockerfile  # Uses the specified Dockerfile
    ports:
      - "8081:3000"  # Maps port 8081 on host to port 3000 in container
    volumes:
      - upload-files:/app/uploads  # Mounts a named volume for uploaded files
    restart: always  # Automatically restarts if stopped

volumes:
  db-vol: {}  # Named volume for MySQL data
  upload-files: {}  # Named volume for uploaded files

networks:
  wp-net: {}  # Custom network for WordPress and MySQL communication

```

## Step 05 - Running Docker Compose

```bash
# Builds, (if needed) and starts all containers defined in the docker-compose.yml file
docker compose up

# Thi command will "freeze" the terminal
```

***We have lost access to the terminal, as Docker Compose was not run in detached mode.***

## Step 06 - Stopping Docker Compose

- Stop your Docker Compose with `CTRL + C`

## Step 07 - Running Docker Compose in detached mode

```bash
# Builds (if needed) and starts all containers in detached (background) mode
docker compose up -d
```

## Step 08 - Checking the Status of Docker Compose Services

```bash
# Lists the status of All Containers Managed by Docker Compose
docker compose ps

docker ps

# How to know if some conteiner has being managed by Docker Compose?
docker inspect <conteiner-id> | grep compose
```

## Step 09 - Accessing the Application

- `EC2_Public-IP:8080` (WordPress)
- `EC2_Public-IP:8081` (Python Upload Application)

## Step 10 - Stopping, starting and pausing containers with Docker Compose:

```bash
# Stops all running containers defined in the Compose file
docker compose stop
docker compose ps

# Starts containers that were previously stopped
docker compose start
docker compose ps

# Pauses all running containers (freezes their processes)
docker compose pause
docker compose ps

# Unpauses all paused containers (resumes their processes)
docker compose unpause
docker compose ps
```

<aside>
💡

### docker compose pause

**Pauses all the containers** defined in the `docker-compose.yml` file, 

**temporarily suspending their processes** (like a "freeze").

- When you use `docker compose pause`, **the application doesn't stay running** - it is **suspended**.
- The container **still appears as "running"**, but **it doesn't process anything** while it's paused.

---

### When to use it:

- To save resources temporarily
- During maintenance or quick adjustments
- *Without stopping and losing container status*

---

</aside>

## Step 11 - Checking Docker Compose logs

```bash
# Displays logs from all services defined in the docker-compose.yml file
docker compose logs
docker compose logs -f
```

## Step 12 - Listing Containers

```bash
docker ps
```

## Step 13 - Listing Images

```bash
docker images
```

## Step 14 - Listing Volumes

```bash
docker volume ls
```

## Step 15 - Listing Networks

```bash
docker network ls
```

## Step 16 - Removing Services from Docker Compose

```bash
# Stops and removes all containers, networks, and volumes created by Docker Compose
docker compose down -v

docker compose ps
docker compose ps -a

docker images
docker volume ls
docker network ls
```