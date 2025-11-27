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
                    sh 'docker build -t timesheet-devops:latest .'
                    sh 'docker run --rm -d --name test-app timesheet-devops:latest'
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
                        trivy image --format json --output trivy-report/trivy-report.json --exit-code 1 --severity CRITICAL,HIGH timesheet-devops:latest || true
                    '''
                }
                archiveArtifacts artifacts: 'trivy-report/trivy-report.json', allowEmptyArchive: true
            }
        }
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    withCredentials([string(credentialsId: 'zap-api-key', variable: 'ZAP_API_KEY')]) {
                        sh """
                            echo '[+] Lancement de OWASP ZAP en mode daemon...'
                            zap.sh -daemon -port 9090 -host 0.0.0.0 -config api.key=$ZAP_API_KEY &
                            sleep 20

                            echo '[+] Lancement du scan ZAP...'
                            curl "http://127.0.0.1:9090/JSON/ascan/action/scan/?url=http://test-app:8080&apikey=$ZAP_API_KEY"

                            progress=0
                            while [ \$progress -lt 100 ]; do
                                progress=\$(curl -s "http://127.0.0.1:9090/JSON/ascan/view/status/?scanId=0&apikey=$ZAP_API_KEY" | jq -r '.status')
                                echo "Scan progress: \$progress%"
                                sleep 5
                            done

                            echo '[+] Génération du rapport ZAP...'
                            curl "http://127.0.0.1:9090/OTHER/core/other/htmlreport/?apikey=$ZAP_API_KEY" -o zap_report.html
                        """
                    }
                }
                archiveArtifacts artifacts: 'zap_report.html', allowEmptyArchive: true
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
            echo "Pipeline terminé avec succès !"
            sh """
            curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"✅ Pipeline terminé avec succès ! Job: ${env.JOB_NAME} Build: #${env.BUILD_NUMBER}"}' \
            $SLACK_WEBHOOK_URL
            """
        }
        failure {
            echo "Le pipeline a échoué !"
            sh """
            curl -X POST -H 'Content-type: application/json' \
            --data '{"text":"❌ Le pipeline a échoué ! Job: ${env.JOB_NAME} Build: #${env.BUILD_NUMBER}"}' \
            $SLACK_WEBHOOK_URL
            """
        }
    }
}
// test trigger
// test trigger
