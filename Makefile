create-cluster:
	# Create cluster using the eksclr CLI tool
	eksctl create cluster \
		--name CapstoneCluster \
		--nodegroup-name capstone-workers \
		--node-type t2.medium \
		--nodes 2 \
		--nodes-min 1 \
		--nodes-max 4 \
		--node-ami auto \
		--region us-east-1 \
		--zones us-east-1a \
		--zones us-east-1b

update-kube-config:
	aws eks --region us-east-1 update-kubeconfig --name CapstoneCluster

all:
	create-cluster update-kube-config