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

        /* ---------------------- OWASP DEPENDENCY CHECK ---------------------- */

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '''--scan .
                    --format HTML
                    --format XML
                    --out dependency-check-report''',
                    installation: 'dependency-check'
            }
        }

        stage('Publish Dependency Check Report') {
            steps {
                dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
            }
        }

        /* ---------------------- DOCKER BUILD & TEST ------------------------- */

        stage('Docker Build & Test') {
            steps {
                script {
                    sh 'docker build -t timesheet-devops:latest .'
                    sh 'docker run --rm -d --name test-app timesheet-devops:latest'
                    sh 'sleep 10'
                    sh 'docker ps | grep test-app'
                    sh 'docker stop test-app'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarServer') {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONARQUBE_TOKEN'
                }
            }
        }
    }

    post {
        success {
            echo "Build Maven, Dependency-Check, Docker et SonarQube terminés avec succès !"
        }
        failure {
            echo "Le pipeline a échoué !"
        }
    }
}
