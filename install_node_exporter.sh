#!/bin/bash

####
# Install and configure current Linux server to be query by Prometheus instance on port 9100/TLS and authentication based
# Needs a configured cert and key file to be used for encryption
# Replace the value contained in password_hashed with the output of the following command: echo 'YOUR_CLEAR_PASSWD' | htpasswd -inBC 10 "" | tr -d ':\n'
# The clear password is needed for accessing the metrics on the prometheus server
##
# The following script is based on this source: https://www.stackhero.io/en-fr/services/Prometheus/documentations/Using-Node-Exporter#add-authentication-to-prometheus-node-exporter
####

node_exporter_version="1.5.0"
node_exporter_release="linux-amd64"
password_hashed='REPLACE_ME'
cert_file='/etc/ssl/prometheus/cert.crt'
key_file='/etc/ssl/prometheus/key.key'

# Download and install node_exporter
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.${node_exporter_release}.tar.gz
tar xvfa node_exporter-${node_exporter_version}.${node_exporter_release}.tar.gz
sudo mv node_exporter-${node_exporter_version}.${node_exporter_release}/node_exporter /usr/local/bin/
rm -fr node_exporter-${node_exporter_version}.${node_exporter_release} node_exporter-${node_exporter_version}.${node_exporter_release}.tar.gz

# Create a user "node_exporter"
sudo useradd -rs /bin/false node_exporter

# Create a systemd service to start node_exporter automatically on boot
sudo cat << 'EOF' > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/prometheus_node_exporter/configuration.yml --collector.systemd --collector.processes

[Install]
WantedBy=multi-user.target
EOF

# Create a configuration directory and file
sudo mkdir -p /etc/prometheus_node_exporter/
sudo touch /etc/prometheus_node_exporter/configuration.yml
sudo chmod 700 /etc/prometheus_node_exporter
sudo chmod 600 /etc/prometheus_node_exporter/*
sudo chown -R node_exporter:node_exporter /etc/prometheus_node_exporter

# Protects metrics with Authentication and TLS
sudo cat << EOF > /etc/prometheus_node_exporter/configuration.yml
basic_auth_users:
  prometheus: ${password_hashed}

tls_server_config:
  cert_file: ${cert_file}
  key_file: ${key_file}

EOF


sudo systemctl daemon-reload
sudo systemctl enable node_exporter

# Start the node_exporter daemon and check its status
sudo systemctl start node_exporter
sudo systemctl status node_exporter