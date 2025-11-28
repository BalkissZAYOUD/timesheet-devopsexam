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
                dependencyCheck additionalArguments: '''--scan . --format HTML --format XML --out dependency-check-report''',
                                odcInstallation: 'dependency-check'
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
                    sh 'docker run --rm -d --name test-app balkiszayoud/timesheet-devops:latest'
                    sh 'sleep 10'
                    sh 'docker ps | grep test-app'
                    sh 'docker stop test-app'
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p zap-report
                        # Lancer OWASP ZAP en mode daemon
                        zap.sh -daemon -port 8090 -host 127.0.0.1 -config api.disablekey=true &
                        sleep 15
                        # Exécuter le scan actif sur l'URL de l'application
                        zap-cli -p 8090 status -t 120
                        zap-cli -p 8090 open-url http://localhost:8080
                        zap-cli -p 8090 spider http://localhost:8080
                        zap-cli -p 8090 active-scan http://localhost:8080
                        zap-cli -p 8090 report -o zap-report/zap-report.html -f html
                    '''
                    archiveArtifacts artifacts: 'zap-report/zap-report.html', allowEmptyArchive: true
                }
            }
        }

        stage('Trivy Docker Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-report
                        trivy clean --java-db || true
                        trivy image --format json --output trivy-report/trivy-report.json \
                            --exit-code 1 --severity CRITICAL,HIGH \
                            balkiszayoud/timesheet-devops:latest || true
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

        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl set image deployment/timesheet-deployment timesheet=balkiszayoud/timesheet-devops:latest'
                sh 'kubectl rollout status deployment/timesheet-deployment'
            }
        }
    }

    post {
        success {
            echo "Pipeline terminé avec succès !"
            script {
                sh """
                    curl -X POST -H "Content-type: application/json" \
                    --data '{"text":"✅ Pipeline terminé avec succès ! Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"}' \
                    $SLACK_WEBHOOK_URL
                """
            }
        }
        failure {
            echo "Le pipeline a échoué !"
            script {
                sh """
                    curl -X POST -H "Content-type: application/json" \
                    --data '{"text":"❌ Le pipeline a échoué ! Job: ${JOB_NAME} Build: #${BUILD_NUMBER}"}' \
                    $SLACK_WEBHOOK_URL
                """
            }
        }
    }
}
