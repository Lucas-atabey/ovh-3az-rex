#!/bin/bash
set -euo pipefail

# Variables d’environnement passées par GitHub
INSTANCE_A=${INSTANCE_A}
INSTANCE_B=${INSTANCE_B}
INSTANCE_C=${INSTANCE_C}
REPO_URL="https://github.com/Lucas-atabey/cleaverCloudKubePoc.git"
BRANCH="main"

echo "🌍 INSTANCE_A=$INSTANCE_A"
echo "🌍 INSTANCE_B=$INSTANCE_B"
echo "🌍 INSTANCE_C=$INSTANCE_C"

echo "📦 Mise à jour des known_hosts"
ssh-keyscan -H $INSTANCE_B >> ~/.ssh/known_hosts
ssh-keyscan -H $INSTANCE_C >> ~/.ssh/known_hosts

echo "⚙️ Déploiement sur le bastion"
export GITHUB_REPOSITORY=$REPO_URL
export GITHUB_SHA=$BRANCH
export FRONT_IP=$INSTANCE_A
bash /home/deployer/deploy.sh

echo "📤 Copie des scripts sur les nœuds"
for NODE in $INSTANCE_B $INSTANCE_C; do
  scp /home/deployer/deploy.sh deployer@$NODE:/home/deployer/deploy.sh
  scp /home/deployer/myApp/backend/.env deployer@$NODE:/home/deployer/.env
done

echo "🚀 Déploiement sur les nœuds"
for NODE in $INSTANCE_B $INSTANCE_C; do
  ssh deployer@$NODE "FRONT_IP=$NODE GITHUB_REPOSITORY=$REPO_URL GITHUB_SHA=$BRANCH bash /home/deployer/deploy.sh"
done

# echo "🔁 Configuration nginx"
# sudo /home/deployer/nginx_deploy.sh $INSTANCE_A $INSTANCE_B $INSTANCE_C
