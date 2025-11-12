pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        IMAGE = "lokhithv/bluegreenapp:${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo '🔄 Pulling latest code from GitHub...'
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🏗️ Building Docker image → ${IMAGE}"
                bat """
                    docker build -t ${IMAGE} .
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "📤 Pushing image to Docker Hub..."
                bat """
                    docker login -u %DOCKERHUB_CREDENTIALS_USR% -p %DOCKERHUB_CREDENTIALS_PSW%
                    docker push ${IMAGE}
                    docker logout
                """
            }
        }

        stage('Blue-Green Deploy') {
            steps {
                echo "🚀 Starting Blue-Green Deployment..."
                // ✅ Run deploy script from repo folder (E:\node-bluegreen)
                bat """
                    powershell -ExecutionPolicy Bypass -File deploy_blue_green.ps1 ${IMAGE}
                """
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful! Active version: ${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Deployment failed! Check logs above."
        }
    }
}
