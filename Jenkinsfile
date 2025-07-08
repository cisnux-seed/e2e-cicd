pipeline{
    agent any

    environment {
        APP_NAME = 'greedy'
        APP_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
        DOCKER_NAMESPACE = 'fajrarisqullas'
        DOCKER_IMAGE = "${DOCKER_NAMESPACE}/${APP_NAME}"
    }

    stages {
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
    }

    post {
        always {
            sh """
                echo "=== Cleanup ==="
                docker image prune -f || true
                echo "=== Cleanup completed ==="
            """
        }
    }
}