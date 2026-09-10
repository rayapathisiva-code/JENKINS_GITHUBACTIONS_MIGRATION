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
      steps { ciPipeline() }
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
