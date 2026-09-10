@Library('shiva-shared-lib') _
pipeline {
  agent any
  options { timestamps() }
 
  environment {
    IMAGE_NAME = 'springboot-jenkins-actions-poc'
    IMAGE_TAG = "${env.GIT_COMMIT}"
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Build & Unit Test') {
      steps { buildAndPushImage() }
    }

    stage('Security & Quality') {
      parallel {
        stage('Security') {
          steps { securityScan() }
        }
        stage('Quality') {
          steps { qualityScan() }
        }
      }
    }

    stage('Docker Build') {
      steps { buildAndPushImage(env.IMAGE_NAME, env.IMAGE_TAG) }
    }

    stage('Generate Deployment Artifact') {
      steps {
        sh 'helm template springboot-poc helm/springboot-poc --set image.repository=$IMAGE_NAME --set image.tag=$IMAGE_TAG > rendered-manifest.yaml'
        publishArtifact()
      }
    }

    stage('DEV Deployment') {
      when { expression { params.DEPLOY_DEV ?: false } }
      steps { deployWithHelm('development', env.IMAGE_NAME, env.IMAGE_TAG) }
    }

    stage('PROD Approval') {
      when { expression { params.DEPLOY_PROD ?: false } }
      steps { input message: 'Approve production deployment?', ok: 'Deploy' }
    }

    stage('PROD Deployment') {
      when { expression { params.DEPLOY_PROD ?: false } }
      steps { deployWithHelm('production', env.IMAGE_NAME, env.IMAGE_TAG) }
    }
  }
}
