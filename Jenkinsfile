pipeline {
    agent any

    environment {
        SONARQUBE_TOKEN = credentials('sonarqube')
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/BalkissZAYOUD/timesheet-devopsexam.git'
            }
        }

        stage('Build Maven') {
            steps {
                sh 'mvn clean install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh """
                        sonar-scanner \
                        -Dsonar.projectKey=timesheet-devopsexam \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=http://192.168.50.4:9000 \
                        -Dsonar.login=${SONARQUBE_TOKEN}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Build Maven terminé avec succès !"
        }
        failure {
            echo "Le build Maven a échoué !"
        }
    }
}
