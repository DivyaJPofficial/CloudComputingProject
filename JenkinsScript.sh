pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                cleanWs()
                sh 'git clone https://github.com/DivyaJPofficial/GradingSystem.git'
            }
        }
        stage('DockerImage') {
            steps {
                echo 'Building Docker Image'
            }
        }
        stage('publish Docker Image'){
            steps {
                echo 'Publish Docker image'
            }
        }
        stage('Create EC2 Instance') {
            steps {
                echo 'Creating EC2 Instance' 
            }
        }
        stage('Deploying FlaskApp') {
            steps {
                echo 'Deploying FlaskApp'
            }
        }
    }
}
