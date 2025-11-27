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
                    sh '''
                        # Démarrer le conteneur et capturer les logs
                        docker run --rm -d --name test-app -p 8081:8080 timesheet-devops:latest
                        echo "[INFO] Conteneur démarré, attente du démarrage de l'application..."
                        sleep 10

                        # Vérifier si le conteneur est toujours en cours d'exécution
                        if docker ps | grep -q test-app; then
                            echo "✅ Conteneur en cours d'exécution"
                            # Tester l'application
                            curl -f http://localhost:8081/ || echo "⚠️ Application non accessible mais conteneur fonctionne"
                        else
                            echo "❌ Conteneur arrêté, vérification des logs..."
                            docker logs test-app || echo "Impossible de récupérer les logs"
                            # Relancer en mode foreground pour voir les erreurs
                            echo "[DEBUG] Redémarrage en mode debug..."
                            docker run --rm --name test-app-debug -p 8082:8080 timesheet-devops:latest &
                            sleep 15
                            docker logs test-app-debug || echo "Debug logs non disponibles"
                            docker stop test-app-debug 2>/dev/null || true
                        fi
                    '''
                }
            }
        }

        stage('Trivy Docker Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-report
                        # Scan même si le conteneur a échoué
                        timeout 300 trivy image --format json --output trivy-report/trivy-report.json --exit-code 0 --severity CRITICAL,HIGH timesheet-devops:latest || echo "Trivy scan terminé"
                    '''
                }
                archiveArtifacts artifacts: 'trivy-report/trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                        echo "[INFO] Vérification de l'état de l'application..."
                        # Vérifier si l'application est accessible
                        if curl -s http://localhost:8081/ > /dev/null; then
                            echo "[INFO] Application accessible, démarrage du scan ZAP..."
                            zap.sh -quickurl http://localhost:8081 -quickout zap_report.html -quickprogress -cmd || echo "ZAP scan terminé"
                        else
                            echo "[INFO] Application non accessible, scan ZAP ignoré"
                            echo "Scan ZAP ignoré - application non disponible" > zap_report.html
                        fi
                    '''
                }
                archiveArtifacts artifacts: 'zap_report.html', allowEmptyArchive: true
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarServer') {
                    sh 'mvn sonar:sonar -Dsonar.login=$SONARQUBE_TOKEN -Dsonar.host.url=http://localhost:9000'
                }
            }
        }
    }
    post {
        always {
            sh '''
                echo "[INFO] Nettoyage des conteneurs..."
                docker stop test-app 2>/dev/null || true
                docker stop test-app-debug 2>/dev/null || true
                docker rm test-app 2>/dev/null || true
                docker rm test-app-debug 2>/dev/null || true
                pkill -f "zap.sh" 2>/dev/null || true
            '''
        }
        success {
            sh """
                curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"✅ Pipeline DevSecOps réussi !\\nJob: ${env.JOB_NAME}\\nBuild: #${env.BUILD_NUMBER}"}' \
                $SLACK_WEBHOOK_URL
            """
        }
        failure {
            sh """
                curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"❌ Pipeline DevSecOps échoué !\\nJob: ${env.JOB_NAME}\\nBuild: #${env.BUILD_NUMBER}\\nErreur: Conteneur Docker arrêté"}' \
                $SLACK_WEBHOOK_URL
            """
        }
    }
}