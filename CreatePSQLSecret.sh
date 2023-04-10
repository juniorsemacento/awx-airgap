#!/bin/bash

# Take user input for database, host, password, and username
read -p "Enter database: " DATABASE
read -p "Enter host: " HOST
read -p "Enter password: " PASSWORD
read -p "Enter username: " USER

# Convert the inputs to base64
DATABASE=$(echo -n "$DATABASE" | base64)
HOST=$(echo -n "$HOST" | base64)
PASSWORD=$(echo -n "$PASSWORD" | base64)
USER=$(echo -n "$USER" | base64)

# Create the tst.yaml file using the template and base64 encoded values
cat <<EOF >awx-postgres-configuration.yaml
apiVersion: v1
data:
  database: $DATABASE
  host: $HOST
  password: $PASSWORD
  port: NTQzMg==
  sslmode: cHJlZmVy
  type: dW5tYW5hZ2Vk
  username: $USER
kind: Secret
metadata:
  name: awx-postgres-configuration
  namespace: awx
EOF

echo "awx-postgres-configuration.yaml file created successfully."
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
kubectl apply -f awx-postgres-configuration.yaml
