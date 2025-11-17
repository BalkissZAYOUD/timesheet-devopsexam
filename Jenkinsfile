pipeline {
    agent any

    environment {
        // Utilisation du token SonarQube stocké dans Jenkins Credentials
        SONARQUBE_TOKEN = credentials('sonarqube')
    }

    stages {
        stage('Checkout') {
            steps {
                // Récupération du code depuis GitHub
                git branch: 'main', url: 'https://github.com/BalkissZAYOUD/timesheet-devopsexam.git'
            }
        }

        stage('Build Maven') {
            steps {
                // Compilation et packaging du projet Maven
                sh 'mvn clean install'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // Injection des variables d'environnement du serveur SonarQube configuré dans Jenkins
                withSonarQubeEnv('SonarServer') {
                    // Analyse du projet directement via Maven (pas besoin de sonar-scanner)
                    sh 'mvn sonar:sonar -Dsonar.login=$SONARQUBE_TOKEN'
                }
            }
        }
    }

    post {
        success {
            echo " Build Maven terminé avec succès !"
        }
        failure {
            echo "Le build Maven a échoué !"
        }
    }
}
