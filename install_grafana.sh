#!/bin/bash

####
# Install Grafana OSS and configures HTTPS listening on port 443
# Assuming valid certs in the files defined below
####

cert_file=/etc/ssl/grafana/cert.crt
key_file=/etc/ssl/grafana/key.key

###
# Repositories and installation

sudo apt-get install -y apt-transport-https
sudo apt-get install -y software-properties-common wget
sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana

####
# HTTPS and Port configuration
# Overriding to permit grafana to listen on 443
sudo mkdir /etc/systemd/system/grafana-server.service.d
sudo cat << "EOF" > /etc/systemd/system/grafana-server.service.d/override.conf
[Service]
# Give the CAP_NET_BIND_SERVICE capability
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

# A private user cannot have process capabilities on the host's user
# namespace and thus CAP_NET_BIND_SERVICE has no effect.
PrivateUsers=false
EOF

sed -i 's/;protocol = http/protocol = https/g' /etc/grafana/grafana.ini
sed -i 's/;http_port = 3000/http_port = 443/g' /etc/grafana/grafana.ini
# Not using conventionnals '/' to make usage of the variables defined above
sed -i "s#;cert_file =#cert_file = $cert_file#g" /etc/grafana/grafana.ini
sed -i "s#;cert_key =#cert_key = $key_file#g" /etc/grafana/grafana.ini

systemctl daemon-reload
systemctl enable --now grafana-server.service
