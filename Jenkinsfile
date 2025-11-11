pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        IMAGE_NAME = "lokhithv/bluegreenapp"
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
                script {
                    IMAGE_TAG = "${env.BUILD_NUMBER}"
                    IMAGE = "${IMAGE_NAME}:${IMAGE_TAG}"

                    echo "🐳 Building Docker Image → ${IMAGE}"
                    bat "docker build -t ${IMAGE} ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "📤 Pushing Image to Docker Hub..."
                bat """
                    docker login -u %DOCKERHUB_CREDENTIALS_USR% -p %DOCKERHUB_CREDENTIALS_PSW%
                    docker push ${IMAGE}
                    docker logout
                """
            }
        }

        stage('Blue-Green Deployment') {
            steps {
                echo "🚦 Running Blue-Green Deployment..."
                bat "powershell -ExecutionPolicy Bypass -File E:\\bluegreen-scripts\\deploy_blue_green.ps1 ${IMAGE}"
            }
        }
    }

    post {
        success {
            echo "✅ Deployment SUCCESSFUL! Now running version: ${BUILD_NUMBER}"
        }
        failure {
            echo "❌ Deployment FAILED — Previous version remains active."
        }
    }
}
