
# awx-airgap - How to configure awx-operator

How to install awx-operator and deploy AWX into an Air-gapped environment.

I'm writting this documento to help others to find the proper information when trying to deploy awx-operator using an offline installation method.

Let me know if you found any problem or can improve this doc.



## Create Private Registry Credentials

What optimizations did you make in your code? E.g. refactors, performance improvements, accessibility

```
# Export the rke2.yaml file
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
 
# First we need to create the awx namespace
kubectl create namespace awx
 
# Create the Secret for the private registry
kubectl create secret docker-registry awx-ee-cp-pull-credentials --docker-server='your-registry.localdomain' --docker-username={EID} --docker-password='{PASSWORD}' -n awx
```

Pay attention to your private registry.

You will need to have all the images necessary loaded into your private registry.

During the first run, you may find that you had the wrong path or missing some images.

Just download and load the images into you private registry.


## Prepping before deploy
> **This installation is using an external PostgreSQL database**

Create the script createPSQLSecret.sh
```
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
```

```
chmod +x CreatePSQLSecret.sh
./CreatePSQLSecret.sh
```

This script will create the **awx-postgres-configuration** secret inside the **awx** namespace.

## Create kustomization.yaml

For this example we are running **awx-operator** 1.3.0.

Create a new file called **kustomization.yaml**

```
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: awx

resources:
  - config/default
  - awx.yaml

images:
  - name: quay.io/ansible/awx-operator
    newName: your-registry.localdomain/quay.io/ansible/awx-operator
    newTag: 1.3.0
  - name: gcr.io/kubebuilder/kube-rbac-proxy
    newName: your-registry.localdomain/gcr.io/kubebuilder/kube-rbac-proxy
    newTag: v0.13.0
```

Create a new file called awx.yaml

```
---
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
spec:
  postgres_configuration_secret: awx-postgres-configuration
  image: your-registry.localdomain/quay.io/ansible/awx
  image_version: '21.13.0'
  init_container_image: your-registry.localdomain/quay.io/ansible/awx-ee
  init_container_image_version: '21.13.0'
  redis_image: your-registry.localdomain/docker.io/redis
  redis_image_version: '7'
  control_plane_ee_image: your-registry.localdomain/quay.io/ansible/awx-ee:21.13.0
  image_pull_secrets:
    - awx-ee-pull-credentials
```

## Create deploy.yaml

You can deploy the awx-operator and awx directly.

But I like to save the kustomize file and run a separate kubectl command to deploy.

```
kubectl kustomize . > deploy.yaml
kubect apply -f deploy.yaml
```

Done
