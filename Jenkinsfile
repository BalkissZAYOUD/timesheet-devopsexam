pipeline {
    agent any

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
