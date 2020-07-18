pipeline {
	agent any
	environment {
		USER = 'schitiz'
		PROJECT = 'udacity-capstone'
		registry = "$USER/$PROJECT"
		registryCredential = 'dockerhub_ID'
  	}

	stages {
		stage('Configure AWS CLI') {
			steps {
				withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', accessKeyVariable: 'AWS_ACCESS_KEY_ID', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY', credentialsId:'aws-credentials']]){
					sh '''
						mkdir -p ~/.aws
						echo "[default]" > ~/.aws/credentials
						echo "aws_access_key_id" = ${AWS_ACCESS_KEY_ID}" >> ~/.aws/credentials
						echo "aws_access_key_id" = ${AWS_SECRET_ACCESS_KEY}" >> ~/.aws/credentials
						echo "aws_access_key_token" = FwoGZXIvYXdzEFYaDCkyjJWlsCtJJWKtqyLIAR/Ec19EKkMIe9k9FIcXcvD6qHjuI3ENxhqf1fEmBAyZPEX2QXTJkGdrH/1sfXCYadk7ohF5MCUETGCwuMVFqWIoMkeV4Rl5AnQ24P6L36NO7Tk9ccb/3B7Tv14fSmWfi82lidv3SnBb9P0DIgSksg5MpX1OX/efwUSi9XmETPVwgqC2g5IlvCfbbsxkLYPNCjgp7cCKhj6faNltzfhid1nIlp6sVdEoT9JhnADcC5dVIGuXFzDPQaSxLJ4sGq1XGxlqZ320r8JFKMrey/gFMi2zYk+TyCAx3eNb/PsPFixLXboGMXt0ZUUdN7xP8uFn1ZbrMTkM2/MJyMb0gsc= >> ~/.aws/credentials
					'''
				}
			}
		}

		// eksctl create cluster \
		// 				--name CapstoneCluster2 \
		// 				--nodegroup-name capstone-workers \
		// 				--node-type t2.small \
		// 				--nodes 2 \
		// 				--nodes-min 1 \
		// 				--nodes-max 4 \
		// 				--node-ami auto \
		// 				--region us-east-1 \
		// 				--zones us-east-1a \
		// 				--zones us-east-1b

		stage('Create Cluster') {
			steps {
				withAWS(region:'us-east-1', credentials:'aws-credentials') {
					sh '''
						true
					'''
				}
			}
		}

		stage('Lint HTML') {
			steps {
				sh 'tidy -q -e *.html'
			}
		}

		stage('Build preparations') {
			steps {
				script {
					gitCommitHash = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
					shortCommitHash = gitCommitHash.take(7)
					VERSION = shortCommitHash
					IMAGE = "$USER/$PROJECT"
				}
			}
		}

		stage('Build Docker Image') {
			steps {
				script {
			    	dockerImage = docker.build("$IMAGE")
			  }
			}
		}

		stage('Publish Container') {
			steps {
				script {
					docker.withRegistry('', registryCredential) {
						dockerImage.push("latest")
						dockerImage.push(VERSION)
          			}
			  	}
			}
		}

		stage('Set current kubectl context') {
			steps {
				withAWS(region:'us-east-1', credentials:'aws-credentials') {
					sh '''
						aws eks --region us-east-1 update-kubeconfig --name udacity-capstone || true
					'''
				}
			}
		}

		stage('Deploy blue container') {
			steps {
				withAWS(region:'us-east-1', credentials:'aws-credentials') {
					sh '''
						kubectl apply -f ./blue-controller.yml || true
					'''
				}
			}
		}

		stage('Deploy green container') {
			steps {
				withAWS(region:'us-east-1', credentials:'aws-credentials') {
					sh '''
						kubectl apply -f ./green-controller.yml || true
					'''
				}
			}
		}

		stage('Create the service in the cluster, redirect to blue') {
			steps {
				withAWS(region:'us-east-1', credentials:'aws-credentials') {
					sh '''
						kubectl apply -f ./blue-service.yml || true
					'''
				}
			}
		}

		stage('Wait user approve') {
            steps {
                input "Ready to redirect traffic to green?"
            }
        }

		stage('Create the service in the cluster, redirect to green') {
			steps {
				withAWS(region:'us-east-1', credentials:'aws-credentials') {
					sh '''
						kubectl apply -f ./green-service.yml || true
					'''
				}
			}
		}
	}
	post {
		always {
		    sh "docker rmi $IMAGE | true"
		}
	}
}
