# Coworking Space Service Extension

The Coworking Space Service is a set of APIs that enable users to request one-time tokens and administrators to authorize access to a coworking space. This service follows a microservice pattern, with APIs split into distinct services that can be deployed and managed independently.

This project focuses on building a production-ready version of the analytics application, which provides business analysts with essential analytics data on user activity within the service.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Setup and Installation](#setup-and-installation)
  - [1. Configure the Database](#1-configure-the-database)
  - [2. Running the Analytics Application Locally](#2-running-the-analytics-application-locally)
- [Deployment](#deployment)
  - [Local Development](#local-development)
  - [Production Deployment](#production-deployment)
- [Continuous Integration and Deployment Pipeline](#continuous-integration-and-deployment-pipeline)
  - [AWS Authentication (`aws-auth`)](#aws-authentication-aws-auth)
- [Monitoring and Logging](#monitoring-and-logging)
- [Cost Optimization](#cost-optimization)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project aims to deploy the analytics application to both local and production environments using Kubernetes and AWS services. The deployment process includes building Docker images, pushing them to AWS ECR (for production), and deploying them to Kubernetes clusters. AWS CodePipeline and CodeBuild are used for continuous integration and deployment in the production environment.

## Prerequisites

### Local Environment

- **Python 3.6+**: To run the application and manage dependencies.
- **Docker CLI**: To build and run Docker images locally.
- **kubectl**: To interact with Kubernetes clusters.
- **Helm**: To manage Kubernetes applications.
- **AWS CLI**: To interact with AWS services.
- **Make**: To automate tasks using the provided Makefile.
- **Minikube** or **Kind**: To run a local Kubernetes cluster for development.

### Remote Resources

- **AWS Account**: To access AWS services like ECR, EKS, CodeBuild, CodePipeline, and CloudWatch.
- **AWS IAM Permissions**: Proper IAM roles and permissions to manage AWS resources.
- **GitHub Repository**: For source code management and integration with AWS CodePipeline.

## Setup and Installation

### 1. Configure the Database

We use a PostgreSQL database deployed via a Helm chart.

#### a. Add the Bitnami Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

#### b. Install PostgreSQL Helm Chart

```bash
helm install coworking-postgres bitnami/postgresql --namespace coworking --create-namespace
```

This command installs PostgreSQL in the `coworking` namespace.

#### c. Retrieve Database Credentials

```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace coworking coworking-postgres-postgresql -o jsonpath="{.data.postgres-password}" | base64 --decode)
echo $POSTGRES_PASSWORD
```

#### d. Run Seed Files

Port-forward the PostgreSQL service to your local machine and run the seed SQL files:

```bash
kubectl port-forward --namespace coworking svc/coworking-postgres-postgresql 5432:5432 &
PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < db/seed.sql
```

### 2. Running the Analytics Application Locally

#### a. Install Dependencies

Navigate to the `analytics` directory and install the required Python packages:

```bash
cd analytics
pip install -r requirements.txt
```

#### b. Set Environment Variables

Create a `.env` file or export the following variables:

```bash
export DB_USERNAME=postgres
export DB_PASSWORD=<YOUR_POSTGRES_PASSWORD>
export DB_HOST=127.0.0.1
export DB_PORT=5432
export DB_NAME=postgres
```

#### c. Run the Application

Start the application using Python:

```bash
python app.py
```

#### d. Verify the Application

- **Daily Usage Report**

  ```bash
  curl http://127.0.0.1:5153/api/reports/daily_usage
  ```

- **User Visits Report**

  ```bash
  curl http://127.0.0.1:5153/api/reports/user_visits
  ```

## Deployment

### Local Development

For local development, you can use a local Kubernetes cluster like Minikube or Kind. The provided Makefile includes commands to automate the deployment to your local cluster.

#### a. Start Minikube

```bash
minikube start --driver=docker
```

#### b. Build the Docker Image Locally

```bash
make build-dev
```

This command builds the Docker image using the local Docker daemon.

#### c. Deploy to Local Kubernetes Cluster

```bash
make k8s-dev-apply
```

This command applies the Kubernetes manifests for local development, deploying the application to your local cluster.

#### d. Install PostgreSQL in Local Kubernetes Cluster

```bash
make postgres-install-dev
```

This command installs PostgreSQL using Helm in your local cluster.

### Production Deployment

The production deployment uses AWS services such as ECR, EKS, CodeBuild, and CodePipeline.

#### a. Build and Push Docker Image to ECR

- **Authenticate Docker to Amazon ECR**

  Ensure you have authenticated your Docker CLI to your Amazon ECR registry:

  ```bash
  aws ecr get-login-password --region <your-region> | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.<your-region>.amazonaws.com
  ```

- **Build the Docker Image**

  ```bash
  make build
  ```

- **Push the Docker Image to ECR**

  ```bash
  make push
  ```

#### b. Deploy to Kubernetes (Production)

- **Connect to EKS Cluster**

  ```bash
  make eks-connect
  ```

- **Deploy PostgreSQL and Application**

  ```bash
  make postgres-install-prod
  make k8s-prod-apply
  ```

These commands will install PostgreSQL using Helm and deploy the application to your EKS cluster.

## Continuous Integration and Deployment Pipeline

An AWS CodePipeline is set up to automate the build and deployment process whenever changes are pushed to the `main` branch in the GitHub repository.

### a. Pipeline Structure

1. **Source Stage**: Retrieves code from GitHub using AWS CodeStar Connections.
2. **Build Stage**: Builds the Docker image using AWS CodeBuild.
3. **Deploy Stage**: Deploys the application to EKS using AWS CodeBuild.

### b. AWS Authentication (`aws-auth`)

To allow AWS CodeBuild to deploy resources to the EKS cluster, the IAM role used by CodeBuild (`coworking_space_codebuild_deploy_role`) must be added to the `aws-auth` ConfigMap in your EKS cluster.

#### Updating `aws-auth` ConfigMap

1. **Edit the ConfigMap**

   ```bash
   kubectl edit configmap aws-auth -n kube-system
   ```

2. **Add the Following Entry Under `mapRoles`**

   ```yaml
   - rolearn: arn:aws:iam::<YOUR_ACCOUNT_ID>:role/coworking_space_codebuild_deploy_role
     username: codebuild:deploy
     groups:
       - system:masters
   ```

This grants the CodeBuild role administrative access to the cluster, enabling it to perform deployments successfully.

**Note**: Granting `system:masters` access provides full admin privileges. For a more secure setup, consider creating a custom role with only the necessary permissions.

## Monitoring and Logging

AWS CloudWatch is used for monitoring logs and application performance:

- **CloudWatch Logs**: Captures logs from the application running in EKS.
- **CloudWatch Metrics**: Monitors CPU, memory usage, and other performance metrics.

Ensure that your application outputs logs to `stdout` and `stderr` so that they can be captured by CloudWatch.

## Cost Optimization

To save on costs:

- **Choose Appropriate EC2 Instances**: Use smaller instance types like `t3.small` for development and `t3.medium` for production workloads.
- **Autoscaling**: Implement cluster autoscaling to adjust resources based on demand.
- **Resource Requests and Limits**: Define reasonable CPU and memory requests and limits in your Kubernetes manifests to optimize resource utilization.

## Contributing

Contributions are welcome! Please fork the repository and create a pull request with your changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

**Note**: For detailed instructions and advanced configurations, refer to the project documentation or contact the project maintainers.

---

## Makefile Overview

The provided Makefile automates various tasks for both local development and production deployment. Below is an overview of the key targets and their purposes.

### Local Development Targets

- **`build-dev`**: Builds the Docker image locally without pushing to any registry.

  ```make
  build-dev:
      docker build -f $(DOCKERFILE_PATH) -t $(IMAGE_NAME):$(IMAGE_TAG) .
  ```

- **`k8s-dev-apply`**: Deploys the application to your local Kubernetes cluster using the manifests in the `deployment-local` directory.

- **`postgres-install-dev`**: Installs PostgreSQL in your local Kubernetes cluster using Helm and the charts in `deployment-local/charts/postgres`.

- **`all-dev`**: Runs all the necessary steps for local development, including building the Docker image, deploying PostgreSQL, and deploying the application.

### Production Deployment Targets

- **`build`**: Builds the Docker image and tags it appropriately for pushing to AWS ECR.

- **`push`**: Pushes the Docker image to AWS ECR, including both the latest image and a cache image for future builds.

- **`eks-connect`**: Configures your `kubectl` context to connect to the EKS cluster.

- **`k8s-prod-apply`**: Deploys the application to the EKS cluster using the manifests in the `deployment` directory.

- **`postgres-install-prod`**: Installs PostgreSQL in the EKS cluster using Helm and the charts in `deployment/charts/postgres`.

- **`all-prod`**: Runs all the necessary steps for production deployment, including building and pushing the Docker image, deploying PostgreSQL, and deploying the application.

### Utility Targets

- **`clean-up`**: Deletes all resources in the `coworking` namespace, including deployments, services, pods, secrets, and configmaps.

- **`start-minikube`** and **`stop-minikube`**: Starts and stops Minikube for local Kubernetes development.

- **`install-*`**: Targets like `install-helm-mac`, `install-aws-cli-mac`, etc., provide commands to install necessary tools on macOS.

### Usage

To execute any of these targets, use the `make` command followed by the target name. For example:

- Local development:

  ```bash
  make all-dev
  ```

- Production deployment:

  ```bash
  make all-prod
  ```

---

**Important**: Before running any of the commands, ensure that you have the necessary AWS permissions and that all variables in the Makefile are correctly set for your environment.
