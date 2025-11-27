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
                dependencyCheck additionalArguments: '''--scan .
                    --format HTML
                    --format XML
                    --out dependency-check-report''',
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
                        trivy image --format json --output trivy-report/trivy-report.json --timeout 600s timesheet-devops:latest
                    '''
                }
            }
        }

stage('OWASP ZAP Scan') {
    steps {
        script {
            sh '''
                export PATH=/opt/zap:$PATH

                # Lancer ZAP en arrière-plan
                zap.sh -daemon -port 8085 -host 127.0.0.1 -config api.disablekey=true &

                echo "Attente du démarrage de ZAP..."
                timeout=60
                while ! curl -s http://127.0.0.1:8085/ > /dev/null; do
                    sleep 2
                    timeout=$((timeout-2))
                    if [ $timeout -le 0 ]; then
                        echo "ZAP n'a pas démarré à temps."
                        exit 1
                    fi
                done

                echo "ZAP est prêt, lancement du spider..."
                curl "http://127.0.0.1:8085/JSON/spider/action/scan/?url=http://localhost:8080"
                sleep 20

                echo "Lancement du active scan..."
                curl "http://127.0.0.1:8085/JSON/ascan/action/scan/?url=http://localhost:8080"
                sleep 30

                echo "Récupération du rapport HTML..."
                curl "http://127.0.0.1:8085/OTHER/core/other/htmlreport/" -o zap_report.html
            '''
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
            echo "Pipeline terminé avec succès !"
            sh """
            curl -X POST -H 'Content-type: application/json' \
            --data '{"text":" Pipeline terminé avec succès ! Job: ${env.JOB_NAME} Build: #${env.BUILD_NUMBER}"}' \
            $SLACK_WEBHOOK_URL
            """
        }
        failure {
            echo "Le pipeline a échoué !"
            sh """
            curl -X POST -H 'Content-type: application/json' \
            --data '{"text":" Le pipeline a échoué ! Job: ${env.JOB_NAME} Build: #${env.BUILD_NUMBER}"}' \
            $SLACK_WEBHOOK_URL
            """
        }
    }
}

////testttgitg