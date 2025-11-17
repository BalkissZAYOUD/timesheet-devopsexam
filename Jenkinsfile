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

        /* ---------------------- TRIVY SCAN ------------------------- */
        stage('Trivy Docker Scan') {
            steps {
                script {
                    sh '''
                        mkdir -p trivy-report
                        trivy image --format json --output trivy-report/trivy-report.json timesheet-devops:latest
                    '''
                }
            }
        }

        /* ---------------------- OWASP ZAP SCAN ------------------------- */
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                        # Lancer ZAP en mode daemon
                        zap.sh -daemon -port 8085 -host 127.0.0.1 -config api.disablekey=true &
                        sleep 20

                        # Lancer un scan avec zap-cli (doit être installé: pip install zap-cli)
                        zap-cli --zap-url http://127.0.0.1 -p 8085 open-url http://localhost:8080
                        zap-cli --zap-url http://127.0.0.1 -p 8085 spider http://localhost:8080
                        zap-cli --zap-url http://127.0.0.1 -p 8085 active-scan http://localhost:8080

                        # Générer un rapport HTML
                        zap-cli --zap-url http://127.0.0.1 -p 8085 report -o zap_report.html -f html
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
            echo "Build Maven, Dependency-Check, Docker, Trivy, ZAP et SonarQube terminés avec succès !"
        }
        failure {
            echo "Le pipeline a échoué !"
        }
    }
}
