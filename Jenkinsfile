@Library('shiva-shared-lib') _

pipeline {
    agent any

    options {
        timestamps()
    }

    environment {
        IMAGE_NAME = 'springboot-jenkins-actions-poc'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.IMAGE_TAG = env.GIT_COMMIT
                }

                echo "Git Commit : ${env.GIT_COMMIT}"
                echo "Image Tag  : ${env.IMAGE_TAG}"
            }
        }

        stage('Build & Unit Test') {
            steps {
                buildAndTest()
            }
        }

        stage('Quality Scan') {
            steps {
                qualityScan()
            }
        }

        stage('Security Scan') {
            steps {
                securityScan()
            }
        }

        /*
        stage('Docker Build') {
            steps {
                buildAndPushImage(
                    imageName: env.IMAGE_NAME,
                    imageTag: env.IMAGE_TAG
                )
            }
        }
        */

        stage('Helm Validation') {
            steps {
                deployWithHelm(
                    environment: 'validation',
                    imageName: env.IMAGE_NAME,
                    imageTag: env.IMAGE_TAG,
                    validationOnly: true
                )
            }
        }

        stage('Archive Artifact') {
            steps {
                publishArtifact()
            }
        }

        stage('DEV Deployment') {
            steps {
                deployWithHelm(
                    environment: 'development',
                    imageName: env.IMAGE_NAME,
                    imageTag: env.IMAGE_TAG
                )
            }
        }
    }

    post {
        success {
            echo "========================================"
            echo "JENKINS CI/CD COMPLETED SUCCESSFULLY"
            echo "Git SHA   : ${env.GIT_COMMIT}"
            echo "Image Tag : ${env.IMAGE_TAG}"
            echo "Environment: development"
            echo "========================================"
        }

        failure {
            echo "Jenkins pipeline failed"
        }
    }
}
