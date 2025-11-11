pipeline {
  agent any
  environment {
    DOCKERHUB_REPO = 'https://hub.docker.com/repository/docker/lokhithv/bluegreenapp'
    DOCKERHUB_CREDS = 'dockerhub-creds'
    IMAGE_TAG = "${env.BUILD_NUMBER}"
    IMAGE = "${env.DOCKERHUB_REPO}:${env.IMAGE_TAG}"
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Build & Test') {
      steps { bat 'npm ci' }
    }
    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.DOCKERHUB_CREDS, usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          bat """
          docker build -t %IMAGE% .
          echo %DH_PASS% | docker login -u %DH_USER% --password-stdin
          docker push %IMAGE%
          docker logout
          """
        }
      }
    }
    stage('Blue-Green Deploy') {
      steps {
        bat "powershell -ExecutionPolicy Bypass -File E:\\bluegreen-scripts\\deploy_blue_green.ps1 ${IMAGE}"
      }
    }
  }
}
