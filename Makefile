# Variables
ACCOUNT_ID = $(shell aws sts get-caller-identity --query "Account" --output text)
IMAGE_NAME=coworking_app
IMAGE_TAG=latest
CACHE_TAG = cache
DOCKERFILE_PATH=./analytics/Dockerfile
K8S_LOCAL_DEPLOYMENT=./deployment-local
K8S_PRODUCTION_DEPLOYMENT=./deployment
ECR_REPOSITORY_URI = $(ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/coworking_space_api
EKS_CLUSTER_NAME=coworking_space_eks_cluster
REGION=us-east-1
HELM_CHART_PATH_LOCAL=./deployment-local/charts/postgres
HELM_CHART_VALUES_LOCAL=./deployment-local/charts/postgres/values.yaml
HELM_CHART_PATH_PROD=./deployment/charts/postgres
HELM_CHART_VALUES_PROD=./deployment/charts/postgres/values.yaml

# Phony targets
.PHONY: all-dev all-prod build push run k8s-dev-apply k8s-dev-delete k8s-prod-apply k8s-prod-delete

# Default "all" for production - runs all production steps
all: all-prod

# All steps for production (build, push, deploy to EKS)
all-prod: build push k8s-prod-apply postgres-install-prod

# All steps for development (build, deploy to local Minikube or other local Kubernetes cluster)
all-dev: build k8s-dev-apply postgres-install-dev

# Build Docker image without BuildKit, using standard caching mechanism
build:
	# Authenticate Docker to the Amazon ECR registry
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ECR_REPOSITORY_URI)
	# Pull the cache image from ECR if it exists
	docker pull $(ECR_REPOSITORY_URI):$(CACHE_TAG) || true
	# Build the image using the cache
	docker build \
	--cache-from=$(ECR_REPOSITORY_URI):$(CACHE_TAG) \
	-f $(DOCKERFILE_PATH) \
	-t $(IMAGE_NAME):$(IMAGE_TAG) .


# Push both the final image and the cache image to Amazon ECR
push:
	# Authenticate Docker to the Amazon ECR registry
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ECR_REPOSITORY_URI)
	# Tag the image with the final tag (e.g., latest)
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(ECR_REPOSITORY_URI):$(IMAGE_TAG)
	# Tag the image with the cache tag
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(ECR_REPOSITORY_URI):$(CACHE_TAG)
	# Push the final image
	docker push $(ECR_REPOSITORY_URI):$(IMAGE_TAG)
	# Push the cache image (so it can be reused in future builds)
	docker push $(ECR_REPOSITORY_URI):$(CACHE_TAG)

# Run Docker container locally for testing (development mode)
run:
	docker run -p 5153:5153 --env-file .env $(IMAGE_NAME):$(IMAGE_TAG)

# Apply Kubernetes deployment for development
k8s-dev-apply:
	kubectl apply -f $(K8S_LOCAL_DEPLOYMENT)/namespace.yaml
	kubectl apply -f $(K8S_LOCAL_DEPLOYMENT)/secret.yaml
	kubectl apply -f $(K8S_LOCAL_DEPLOYMENT)/configmap.yaml
	export DOCKER_IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG); \
	envsubst < $(K8S_LOCAL_DEPLOYMENT)/coworking.yaml | kubectl apply -f -

# Delete Kubernetes deployment for development
k8s-dev-delete:
	kubectl delete -f $(K8S_LOCAL_DEPLOYMENT)/coworking.yaml
	kubectl delete -f $(K8S_LOCAL_DEPLOYMENT)/configmap.yaml
	kubectl delete -f $(K8S_LOCAL_DEPLOYMENT)/secret.yaml

# Connect to EKS cluster
eks-connect:
	aws eks --region $(REGION) update-kubeconfig --name $(EKS_CLUSTER_NAME)

# Apply Kubernetes deployment to EKS for production
k8s-prod-apply: eks-connect
	kubectl apply -f $(K8S_PRODUCTION_DEPLOYMENT)/namespace.yaml || true
	kubectl apply -f $(K8S_PRODUCTION_DEPLOYMENT)/configmap.yaml
	export DB_USERNAME=$(shell aws secretsmanager get-secret-value --secret-id coworking_space_db_credentials --query 'SecretString' --output text | jq -r '.username'); \
	export DB_PASSWORD=$(shell aws secretsmanager get-secret-value --secret-id coworking_space_db_credentials --query 'SecretString' --output text | jq -r '.password'); \
	export ECR_REPOSITORY_URI=$(ECR_REPOSITORY_URI) DOCKER_IMAGE_NAME=$(IMAGE_NAME) IMAGE_TAG=$(IMAGE_TAG); \
	envsubst < $(K8S_PRODUCTION_DEPLOYMENT)/coworking.yaml | kubectl apply -f -
	kubectl rollout restart deployment coworking -n coworking || true

# Delete Kubernetes production deployment from EKS
k8s-prod-delete: eks-connect
	kubectl delete -f $(K8S_PRODUCTION_DEPLOYMENT)/coworking.yaml
	kubectl delete -f $(K8S_PRODUCTION_DEPLOYMENT)/configmap.yaml

# Fetch secrets from AWS Secrets Manager and create Kubernetes secret
create-postgres-secret-prod:
	export DB_USERNAME=$(shell aws secretsmanager get-secret-value --secret-id coworking_space_db_credentials --query 'SecretString' --output text | jq -r '.username'); \
	export DB_PASSWORD=$(shell aws secretsmanager get-secret-value --secret-id coworking_space_db_credentials --query 'SecretString' --output text | jq -r '.password'); \
	export DB_ADMIN_PASSWORD=$(shell aws secretsmanager get-secret-value --secret-id coworking_space_db_credentials --query 'SecretString' --output text | jq -r '.postgresPassword'); \
	kubectl create secret generic postgres-secret \
	--namespace=coworking \
	--from-literal=username=$$DB_USERNAME \
	--from-literal=password=$$DB_PASSWORD \
	--from-literal=postgresPassword=$$DB_ADMIN_PASSWORD || true

postgres-install-dev:
	if kubectl get configmap init-scripts-configmap --namespace=coworking; then \
		echo "ConfigMap 'init-scripts-configmap' already exists in namespace 'coworking'."; \
	else \
		echo "Creating ConfigMap 'init-scripts-configmap'..."; \
		kubectl create configmap init-scripts-configmap --from-file=db/ --namespace=coworking; \
	fi
	kubectl apply -f $(K8S_LOCAL_DEPLOYMENT)/secret.yaml
	helm dependency update ${HELM_CHART_PATH_LOCAL}
	helm upgrade --install postgres $(HELM_CHART_PATH_LOCAL) \
	--namespace coworking \
	--create-namespace \
	-f $(HELM_CHART_VALUES_LOCAL)

postgres-install-prod: create-postgres-secret-prod
	if kubectl get configmap init-scripts-configmap --namespace=coworking; then \
		echo "ConfigMap 'init-scripts-configmap' already exists in namespace 'coworking'."; \
	else \
		echo "Creating ConfigMap 'init-scripts-configmap'..."; \
		kubectl create configmap init-scripts-configmap --from-file=db/ --namespace=coworking; \
	fi
	export DB_PASSWORD=$(shell aws secretsmanager get-secret-value --secret-id coworking_space_db_credentials --query 'SecretString' --output text | jq -r '.password')
	helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
	helm repo update
	helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
	--namespace kube-system \
	--set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-ebs-csi-driver \
	--set controller.serviceAccount.create=true \
	--set controller.replicaCount=2
	helm dependency update ${HELM_CHART_PATH_PROD}
	helm upgrade --install postgres $(HELM_CHART_PATH_PROD) \
	--namespace coworking \
	--create-namespace \
	-f $(HELM_CHART_VALUES_PROD) \
	--set global.postgresql.auth.password=$DB_PASSWORD

# Start Minikube
start-minikube:
	minikube start --driver=docker

# Stop Minikube
stop-minikube:
	minikube stop

# Install Minikube on macOS
install-minikube-mac:
	brew install minikube

# Install Helm
install-helm-mac:
	brew install helm

# Install AWS CLI
install-aws-cli-mac:
	brew install awscli

# Install Docker
install-docker-mac:
	brew install docker

# Install kubectl
install-kubectl-mac:
	brew install kubectl

# Clean up all resources
clean-up:
	kubectl delete deployment --all -n coworking
	kubectl delete svc --all -n coworking
	kubectl delete pod --all -n coworking
	kubectl delete secret --all -n coworking
	kubectl delete configmap --all -n coworking
	kubectl delete namespace coworking
