#!/bin/bash
set -euo pipefail

echo "🔁 Pull latest backend code"
sudo rm -rf ~/myApp

git clone ${GITHUB_REPOSITORY} ~/myApp
cd ~/myApp
git checkout ${GITHUB_SHA}

echo "📦 Install backend dependencies"
cp /home/deployer/.env ~/myApp/backend/.env
source /home/deployer/venv/bin/activate
pip install -r ~/myApp/backend/requirements.txt

echo "🚀 Restart backend.service"
sudo systemctl restart backend.service

echo "🛠️ Build frontend"
cd ~/myApp/frontend/frontend
npm install
npm run build

cd ~/myApp/frontend/server
npm install
mkdir -p ~/myApp/frontend/server/public
cp -r ~/myApp/frontend/frontend/dist/* ~/myApp/frontend/server/public/

echo "📂 Copy config.json"
mkdir -p ~/myApp/frontend/server/public/config
cat > ~/myApp/frontend/server/public/config/config.json <<EOF
{
  "BACKEND_URL": "http://57.130.28.79:5000",
  "FRONT_IP": "${FRONT_IP}"
}
EOF

  # "BACKEND_URL": "/api",


echo "🚀 Restart frontend.service"
sudo systemctl restart frontend.service
