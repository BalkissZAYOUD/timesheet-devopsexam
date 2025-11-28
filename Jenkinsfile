pipeline {
    agent any
    environment {
        SONARQUBE_TOKEN = credentials('sonarqube')
        SLACK_WEBHOOK_URL = credentials('slack-webhook')
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

        stage('OWASP Dependency Check') {
            steps {
                sh 'mkdir -p dependency-check-report'
                dependencyCheck additionalArguments: '''--scan . --format HTML --format XML --out dependency-check-report''', odcInstallation: 'dependency-check'
            }
        }

        stage('Publish Dependency Check Report') {
            steps {
                dependencyCheckPublisher pattern: 'dependency-check-report/dependency-check-report.xml'
            }
        }

        stage('Docker Build & Test') {
            steps {
                script {
                    sh 'docker build -t balkiszayoud/timesheet-devops:latest .'
                    // On teste sans exposer le port pour éviter conflit avec Jenkins
                    sh 'docker run --rm -d --name test-app balkiszayoud/timesheet-devops:latest'
                    sh 'sleep 10'
                    sh 'docker ps | grep test-app'
                    sh 'docker stop test-app'
                }
            }
        }

        stage('Trivy Docker Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-report
                        trivy clean --java-db || true
                        trivy image --format json --output trivy-report/trivy-report.json --exit-code 1 --severity CRITICAL,HIGH balkiszayoud/timesheet-devops:latest || true
                    '''
                }
                archiveArtifacts artifacts: 'trivy-report/trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('Docker Push to Hub') {
            steps {
                script {
                    withDockerRegistry([credentialsId: 'dockerhub', url: '']) {
                        sh 'docker push balkiszayoud/timesheet-devops:latest'
                    }
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

     stage('Deploy to Minikube') {
         steps {
             sh 'minikube image load balkiszayoud/timesheet-devops:latest'
             sh 'kubectl rollout restart deployment/timesheet-deployment'
         }
     }


    post {
        success {
            echo "Pipeline terminé avec succès !"
            sh """
            curl -X POST -H "Content-type: application/json" \
            --data '{"text":"✅ Pipeline terminé avec succès ! Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"}' \
            $SLACK_WEBHOOK_URL
            """
        }
        failure {
            echo "Le pipeline a échoué !"
            sh """
            curl -X POST -H "Content-type: application/json" \
            --data '{"text":"❌ Le pipeline a échoué ! Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"}' \
            $SLACK_WEBHOOK_URL
            """
        }
    }
}
