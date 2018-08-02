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

echo "Start the AngularJs Solution"
echo "Git pull AngularJs demo"
 cd /home/${demo_username}
 git clone https://github.com/GuyBarros/mean_cluster
 cd /home/${demo_username}/mean_cluster
 echo "install the Nodejs package"
 sudo npm install 
 sudo bower install --allow-root
 sudo gulp serve
# sudo nodemon server.js &>/dev/null


echo "==> Consul Connect Demo Setup is Done!"


