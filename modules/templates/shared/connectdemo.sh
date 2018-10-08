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

echo "--> Configuring the apt repo for mongodb"
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt-get update
#sudo apt-get install -y mongodb-org
echo "--> Done configuring the apt repo for mongodb"

#echo "--> Cloning mean cluster gits"
#sudo mkdir -p  /home/training/mean_cluster_backend/ /home/training/mean_cluster/
#sudo git clone https://github.com/GuyBarros/mean_cluster_backend /home/training/mean_cluster_backend
#sudo git clone https://github.com/GuyBarros/mean_cluster /home/training/mean_cluster/
#echo "--> Done cloning mean cluster gits"

echo "--> Auto config"
case $HOSTNAME in
  ("emea-se-mongodb.node.consul") sudo apt-get install -y mongodb-org
  sudo systemctl restart mongod
  echo "configured mongodb server";;
  ("emea-se-nodejs.node.consul") cd /home/${demo_username}
 git clone https://github.com/GuyBarros/mean_cluster_backend
 echo "configured nodejs server";;
("emea-se-angularjs.node.consul") cd /home/${demo_username}
 git clone https://github.com/GuyBarros/mean_cluster
echo "configured angularjs server";;
(*)   echo "None of tye above";;
esac
echo "--> Done auto config"

echo "==> Consul Connect Demo Setup is Done!"


