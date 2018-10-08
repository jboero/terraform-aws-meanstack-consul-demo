#!/usr/bin/env bash
set -e

echo "==> Consul Connect Demo Setup"


echo "--> Configuring mongodb"
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.0.list
sudo apt-get update
sudo apt-get install -y mongodb-org
sudo systemctl restart mongod
echo "--> Done configuring  mongodb"

echo "--> copy the conf file mongodb"
sudo cp -f /tmp/mongod.conf /etc/mongod.conf
sudo systemctl restart mongod

echo "--> copy the mongodb is maser script"
sudo cp -f /tmp/mongo_is_master.sh /etc/consul.d/mongo_is_master.sh
sudo chmod +x  /etc/consul.d/mongo_is_master.sh

echo "==> Consul Connect Demo Setup is Done!"


