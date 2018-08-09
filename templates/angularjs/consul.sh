#!/usr/bin/env bash
set -e

echo "==> Consul (client)"

echo "--> Fetching"
install_from_url "consul" "${consul_url}"

echo "--> Writing configuration"
sudo mkdir -p /mnt/consul
sudo mkdir -p /etc/consul.d
sudo tee /etc/consul.d/config.json > /dev/null <<EOF
{
  "advertise_addr": "$(private_ip)",
  "advertise_addr_wan": "$(public_ip)",
  "bind_addr": "0.0.0.0",
  "data_dir": "/mnt/consul",
  "disable_update_check": true,
  "encrypt": "${consul_gossip_key}",
  "leave_on_terminate": true,
  "node_name": "${node_name}",
  "raft_protocol": 3,
  "retry_join": ["provider=aws tag_key=${consul_join_tag_key} tag_value=${consul_join_tag_value}"],

  "addresses": {
    "http": "0.0.0.0",
    "https": "0.0.0.0"
  },
  "ports": {
    "http": 8500,
    "https": 8533
  },
  "key_file": "/etc/ssl/certs/me.key",
  "cert_file": "/etc/ssl/certs/me.crt",
  "ca_file": "/usr/local/share/ca-certificates/01-me.crt",
  "verify_server_hostname": false,
  "verify_incoming": false,
  "verify_outgoing": false,
   "ui": true,
 "connect":{
  "enabled": true,
      "proxy": {  "allow_managed_root": true  }
      }
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/consul.sh > /dev/null <<"EOF"
alias conslu="consul"
alias ocnsul="consul"
EOF
source /etc/profile.d/consul.sh

echo "--> Creating training service"
sudo tee /etc/consul.d/training.json > /dev/null <<"EOF"
{
  "service": {
    "name": "training",
    "port": 1991
  }
}
EOF

echo "--> Creating Angular js service"
sudo tee /etc/consul.d/angularjs.json > /dev/null <<"EOF"
{
    "service": {
      "name": "angularjs",
      "port": 3000,
      "connect": {
        "proxy": {
          "config": {
            "upstreams": [{
               "destination_name": "nodejs",
               "local_bind_address": "0.0.0.0",
               "local_bind_port": 5000
            }]
          }
        }
      }
    },
    "checks": [
       {
        "id": "angular",
        "name": "web server up and running",
        "tcp": "localhost:3000",
        "interval": "30s",
        "timeout": "1s"
      }
    ]
  }
EOF


echo "--> Making consul.d world-writable..."
sudo chmod 0777 /etc/consul.d/

echo "--> Generating systemd configuration"
sudo tee /etc/systemd/system/consul.service > /dev/null <<"EOF"
[Unit]
Description=Consul
Documentation=https://www.consul.io/docs/
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul agent -config-dir="/etc/consul.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable consul
sudo systemctl start consul

echo "--> Installing dnsmasq"
ssh-apt install dnsmasq
sudo tee /etc/dnsmasq.d/10-consul > /dev/null <<"EOF"
server=/consul/127.0.0.1#8600
no-poll
server=8.8.8.8
server=8.8.4.4
cache-size=0
EOF
sudo systemctl enable dnsmasq
sudo systemctl restart dnsmasq

echo "==> Consul is done!"
