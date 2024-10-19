# Variables
IMAGE_NAME = coworking_app
IMAGE_TAG = latest
DOCKERFILE_PATH = ./analytics/Dockerfile
K8S_LOCAL_DEPLOYMENT = ./deployment-local
K8S_PRODUCTION_DEPLOYMENT = ./deployment
ECR_REPOSITORY_URI = <YOUR ECR REPO URI>
REGION = us-east-1
HELM_CHART_PATH_LOCAL = ./deployment-local/charts/postgres
HELM_CHART_VALUES_LOCAL = ./deployment-local/charts/postgres/values.yaml

# Phony targets
.PHONY: all-dev all-prod build push run k8s-dev-apply k8s-dev-delete k8s-prod-apply k8s-prod-delete

# Default "all" for production - runs all production steps
all: all-prod

# All steps for production (build, push, deploy to EKS)
all-prod: build push k8s-prod-apply

# All steps for development (build, deploy to local Minikube or other local Kubernetes cluster)
all-dev: build postgres-install-dev k8s-dev-apply

# Build Docker image
build:
	docker build -f $(DOCKERFILE_PATH) -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Push Docker image to Amazon ECR (for production)
push:
	# Authenticate Docker to the Amazon ECR registry
	aws ecr get-login-password --region $(REGION) | docker login --username AWS --password-stdin $(ECR_REPOSITORY_URI)
	# Tag the image
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(ECR_REPOSITORY_URI):$(IMAGE_TAG)
	# Push the image to ECR
	docker push $(ECR_REPOSITORY_URI):$(IMAGE_TAG)

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

# Apply Kubernetes deployment to EKS for production
k8s-prod-apply:
	kubectl apply -f $(K8S_PRODUCTION_DEPLOYMENT)/configmap.yaml
	kubectl apply -f $(K8S_PRODUCTION_DEPLOYMENT)/coworking.yaml

# Delete Kubernetes production deployment from EKS
k8s-prod-delete:
	kubectl delete -f $(K8S_PRODUCTION_DEPLOYMENT)/coworking.yaml
	kubectl delete -f $(K8S_PRODUCTION_DEPLOYMENT)/configmap.yaml

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
