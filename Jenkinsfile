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

        stage('Docker Build & Test') {
            steps {
                script {
                    // Build l'image Docker avec sudo
                    sh 'sudo docker build -t timesheet-devops:latest .'

                    // Lancer le conteneur pour test rapide avec sudo
                    sh 'sudo docker run --rm -d --name test-app timesheet-devops:latest'

                    // Attendre quelques secondes pour vérifier le démarrage
                    sh 'sleep 10'

                    // Vérifier que le conteneur tourne
                    sh 'sudo docker ps | grep test-app'

                    //Arrêter et supprimer le conteneur de test avec sudo
                    sh 'sudo docker stop test-app'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // Injection des variables d'environnement du serveur SonarQube configuré dans Jenkins
                withSonarQubeEnv('SonarServer') {
                    // Analyse du projet directement via Maven
                    sh 'mvn sonar:sonar -Dsonar.login=$SONARQUBE_TOKEN'
                }
            }
        }
    }

    post {
        success {
            echo "Build Maven, Docker et SonarQube terminés avec succès !"
        }
        failure {
            echo "Le pipeline a échoué !"
        }
    }
}
