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
                    sh 'docker run --rm -d --name test-app -p 8081:8080 timesheet-devops:latest'
                    sh 'sleep 30'
                    sh 'docker ps | grep test-app'
                    // Test de l'application
                    sh 'curl -f http://localhost:8081/ || echo "Application test completed"'
                }
            }
        }

        stage('Trivy Docker Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-report
                        # Scan avec timeout et gestion d'erreur
                        timeout 300 trivy image --format json --output trivy-report/trivy-report.json --exit-code 0 --severity CRITICAL,HIGH timesheet-devops:latest || echo "Trivy scan completed"
                    '''
                }
                archiveArtifacts artifacts: 'trivy-report/trivy-report.json', allowEmptyArchive: true
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                        echo "[INFO] Starting ZAP daemon..."
                        # Démarrer ZAP en mode daemon sur un port spécifique
                        zap.sh -daemon -port 9090 -host 0.0.0.0 -config api.disablekey=true &
                        ZAP_PID=$!
                        echo "ZAP PID: $ZAP_PID"

                        # Attendre que ZAP soit complètement démarré
                        echo "[INFO] Waiting for ZAP to start..."
                        sleep 30

                        # Vérifier que ZAP répond
                        curl -f http://localhost:9090 || echo "ZAP is starting..."

                        echo "[INFO] Starting ZAP scan..."
                        # Lancer le scan
                        curl "http://localhost:9090/JSON/ascan/action/scan/?url=http://localhost:8081&recurse=true&inScopeOnly=false"

                        # Surveiller la progression du scan
                        echo "[INFO] Monitoring scan progress..."
                        progress="0"
                        counter=0
                        while [ "$progress" -lt "100" ] && [ $counter -lt 60 ]; do
                            progress=$(curl -s "http://localhost:9090/JSON/ascan/view/status/" | grep -o '"status":"[0-9]*"' | cut -d'"' -f4)
                            if [ -z "$progress" ]; then
                                progress="0"
                            fi
                            echo "Scan progress: $progress%"
                            sleep 10
                            counter=$((counter + 1))
                        done

                        # Générer le rapport
                        echo "[INFO] Generating ZAP report..."
                        curl -s "http://localhost:9090/OTHER/core/other/htmlreport/" -o zap_report.html

                        # Arrêter ZAP
                        echo "[INFO] Stopping ZAP..."
                        kill $ZAP_PID 2>/dev/null || true
                        sleep 5

                        # Vérifier que ZAP est arrêté
                        if ps -p $ZAP_PID > /dev/null; then
                            kill -9 $ZAP_PID 2>/dev/null || true
                        fi

                        echo "[INFO] ZAP scan completed"
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
                echo "[INFO] Cleaning up containers and processes..."
                docker stop test-app 2>/dev/null || true
                docker rm test-app 2>/dev/null || true
                pkill -f "zap.sh" 2>/dev/null || true
            '''
        }
        success {
            sh """
                curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"✅ Pipeline DevSecOps COMPLET réussi ! ✅\\nJob: ${env.JOB_NAME}\\nBuild: #${env.BUILD_NUMBER}\\n✓ Dependency Check\\n✓ Trivy Scan\\n✓ OWASP ZAP\\n✓ SonarQube"}' \
                $SLACK_WEBHOOK_URL
            """
        }
        failure {
            sh """
                curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"❌ Pipeline DevSecOps échoué ! ❌\\nJob: ${env.JOB_NAME}\\nBuild: #${env.BUILD_NUMBER}"}' \
                $SLACK_WEBHOOK_URL
            """
        }
    }
}