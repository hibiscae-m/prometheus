#!/bin/bash

####
# Installs and configures a Prometheus instance with TLS and authentication based
# Replace the value contained in password_hashed with the output of the following command: echo 'YOUR_CLEAR_PASSWD' | htpasswd -inBC 10 "" | tr -d ':\n'
# The clear password is needed for accessing Prometheus' data with your third party tool (assuming Grafana)
# If you're planning of using an other tool than Grafana, consider replacing the user 'grafana' set in web-config.yml (down below) for consistancy
####

prometheus_version="2.42.0"
prometheus_release="linux-amd64"
password_hashed='REPLACE_ME'
cert_file='/etc/ssl/prometheus/cert.crt'
key_file='/etc/ssl/prometheus/key.key'

# Set the data and configuration directories
sudo mkdir /var/prometheus
sudo mkdir /etc/prometheus

# Download and Install
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v$prometheus_version/prometheus-$prometheus_version.$prometheus_release.tar.gz
tar xvfa prometheus-$prometheus_version.$prometheus_release.tar.gz
sudo mv prometheus-$prometheus_version.$prometheus_release/prometheus /usr/local/bin
sudo mv prometheus-$prometheus_version.$prometheus_release/promtool /usr/local/bin
sudo mv prometheus-$prometheus_version.$prometheus_release/prometheus.yml /etc/prometheus

# Create a systemd service
sudo cat << 'EOF' > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --web.config.file=/etc/prometheus/web-config.yml --storage.tsdb.path=/var/prometheus/data

[Install]
WantedBy=multi-user.target
EOF

# Protects prometheus with Authentication and TLS
sudo cat << EOF > /etc/prometheus/web-config.yml
basic_auth_users:
  grafana: ${password_hashed}

tls_server_config:
  cert_file: ${cert_file}
  key_file: ${key_file}

EOF

# Create a user "prometheus" and assigning rights
sudo useradd -rs /bin/false prometheus

chown -R root:prometheus /etc/prometheus
chmod 750 /etc/prometheus
chmod 640 /etc/prometheus/*

chown -R prometheus:prometheus /var/prometheus
chmod 750 /var/prometheus

# Enable and start prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus
