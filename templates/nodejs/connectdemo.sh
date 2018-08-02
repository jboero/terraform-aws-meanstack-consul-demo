#!/usr/bin/env bash
set -e

echo "==> Consul Connect Demo Setup"


echo "--> Installing common dependencies"
ssh-apt install \
  nodejs \
  npm \
  &>/dev/null
  echo "-->Done installing common dependencies"

echo "--> Installing common npm dependencies"
sudo npm install -g gulp
sudo npm install -g bower
sudo npm install -g nodemon
sudo npm install -g pm2
echo "--> Done installing common npm dependencies"


echo "Start the Nodejs Solution"
echo "Git pull nodejs demo"
 cd /home/${demo_username}
 git clone https://github.com/GuyBarros/mean_cluster_backend
 cd /home/${demo_username}/mean_cluster_backend
 echo "install the Nodejs package"
 npm install 
 sudo nodemon server.js &>/dev/null

 # sudo pm2 start server.js --name nodejs-backend &>/dev/null
# pm2 start server.js &


echo "==> Consul Connect Demo Setup is Done!"


