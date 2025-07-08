pipeline{
    agent any

    tools {
      maven 'Maven Latest'
      jdk 'JDK Latest'
    }

    environment {
        APP_NAME = 'greedy'
        APP_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        DOCKER_NAMESPACE = 'fajrarisqulla'
        DOCKER_IMAGE = "${DOCKER_NAMESPACE}/${APP_NAME}"

        // GCP Configuration for Terraform
        GCP_PROJECT_ID = 'rakamin-ttc-odp-it-4'
        GCP_REGION = 'asia-southeast2'
        DISCORD_WEBHOOK_URL = credentials('discord-webhook-url')

    }

    stages {
        stage('Parallel Testing and Analysis') {
            parallel {
                stage('Unit Test') {
                    steps {
                        sh "mvn test"
                    }
                }

                stage('Static Code Analysis (SAST) via Sonar') {
                    steps {
                        sh """
                            mvn clean compile sonar:sonar \
                              -Dsonar.projectKey=springboot \
                              -Dsonar.projectName='springboot' \
                              -Dsonar.host.url=http://sonarqube:9000 \
                              -Dsonar.token=sqp_3a35478c4c1e07878cd1c5e500461c025b105767
                        """
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                                                   passwordVariable: 'DOCKER_PASSWORD',
                                                   usernameVariable: 'DOCKER_USERNAME')]) {

                        sh """
                            echo "=== Docker Login ==="
                            echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin

                            echo "=== Building Docker Image ==="
                            # Build image with version tag
                            docker build -t ${DOCKER_IMAGE}:${APP_VERSION} --build-arg JAR_FILE=build/libs/*.jar .

                            echo "=== Docker build completed ==="
                        """

                        if (env.BRANCH_NAME == 'main') {
                            sh """
                                echo "=== Building and pushing latest tag ==="
                                docker build -t ${DOCKER_IMAGE}:latest --build-arg JAR_FILE=build/libs/*.jar .
                                docker push ${DOCKER_IMAGE}:latest
                            """
                        } else if (env.BRANCH_NAME == 'develop') {
                            sh """
                                echo "=== Building and pushing develop tag ==="
                                docker build -t ${DOCKER_IMAGE}:develop --build-arg JAR_FILE=build/libs/*.jar .
                                docker push ${DOCKER_IMAGE}:develop
                            """
                        }

                        sh """
                            echo "=== Pushing version tag ==="
                            docker push ${DOCKER_IMAGE}:${APP_VERSION}
                            docker logout
                        """
                    }
                }
            }
        }

        stage('Terraform Deploy') {
            steps {
                script {
                    // Method 1: Using Service Account Key for Terraform ADC
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
                        sh """
                            echo "=== Setting up GCP Application Default Credentials for Terraform ==="

                            # Set the environment variable that Terraform will use
                            export GOOGLE_APPLICATION_CREDENTIALS=\$GOOGLE_APPLICATION_CREDENTIALS

                            # Optional: Also authenticate gcloud (if you need gcloud commands)
                            gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                            gcloud config set project ${GCP_PROJECT_ID}

                            echo "=== Running Terraform ==="
                            pwd
                            cd terraform/
                            terraform init
                            terraform plan
                            terraform apply -auto-approve
                        """
                    }
                }
            }
        }
    }

    post {
//         success {
//             echo "Pipeline berhasil 🚀"
//             echo "Docker image berhasil di-push ke Docker Hub: ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
//
//             sh """
//             curl -H "Content-Type: application/json" \
//                 -X POST \
//                 -d '{
//                 "content": "*✅ Build Sukses!*\\nProject: ${DOCKER_IMAGE_NAME}\\nTag: ${DOCKER_TAG}\\nStage: Success 🚀"
//                 }' \
//                 ${DISCORD_WEBHOOK_URL}
//             """
//         }
//
//         failure {
//             echo "Pipeline gagal 💥"
//
//             sh """
//             curl -H "Content-Type: application/json" \
//                 -X POST \
//                 -d '{
//                 "content": "*❌ Build Gagal!*\\nProject: ${DOCKER_IMAGE_NAME}\\nTag: ${DOCKER_TAG}\\nStage: Failed 💥"
//                 }' \
//                 ${DISCORD_WEBHOOK_URL}
//             """
//
//             // Cleanup Docker images
//             sh """
//             docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} || true
//             docker rmi ${DOCKER_IMAGE_NAME}:latest || true
//             """
//         }
        always {
            sh """
                echo "=== Cleanup ==="
                docker image prune -f || true

                # Clean up GCP auth (optional)
                gcloud auth revoke --all || true

                echo "=== Cleanup completed ==="
            """
        }
    }
}