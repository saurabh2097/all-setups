#!/bin/bash

# -------------------------------------
# 1. Install Helm
# -------------------------------------
echo "Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
helm version

# -------------------------------------
# 2. Install Argo CD using Helm
# -------------------------------------
echo "Adding Argo CD Helm repo and installing Argo CD..."
helm repo add argo-cd https://argoproj.github.io/argo-helm
helm repo update

kubectl create namespace argocd
helm install argocd argo-cd/argo-cd -n argocd

# Wait for resources to get created
echo "Waiting for Argo CD pods to start..."
kubectl get all -n argocd

# -------------------------------------
# 3. Expose Argo CD server via LoadBalancer
# -------------------------------------
echo "Exposing Argo CD server as LoadBalancer..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Install jq (JSON processor)
echo "Installing jq..."
sudo apt update -y && sudo apt install -y jq

# Wait for LoadBalancer IP/hostname to be available
echo "Fetching Argo CD LoadBalancer endpoint..."
sleep 10
ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')
echo "Argo CD Server Hostname: $ARGOCD_SERVER"

# -------------------------------------
# 4. Get Argo CD Initial Admin Password
# -------------------------------------
echo "Fetching Argo CD initial admin password..."
ARGO_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD Admin Password: $ARGO_PWD"

# -------------------------------------
# Done
# -------------------------------------
echo "✅ Argo CD installation completed!"
echo "🌐 Access it at: http://$ARGOCD_SERVER"
echo "🔑 Username: admin"
echo "🔑 Password: $ARGO_PWD"
