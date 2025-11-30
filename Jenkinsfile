pipeline {
    agent any

    environment {
        SONARQUBE_TOKEN   = credentials('sonarqube')
        SLACK_WEBHOOK_URL = credentials('slack-webhook')
    }

    stages {

        /* ------------------------ CHECKOUT ------------------------ */
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/BalkissZAYOUD/timesheet-devopsexam.git'
            }
        }

        /* ------------------------ MAVEN BUILD ------------------------ */
        stage('Build Maven') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    sh 'mvn clean install'
                }
            }
        }

        /* ------------------------ SONARQUBE ------------------------ */
        stage('SonarQube Analysis') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    withSonarQubeEnv('sonarqube-server') {
                        sh '''
                            mvn sonar:sonar \
                                -Dsonar.projectKey=timesheet \
                                -Dsonar.host.url=http://localhost:9000 \
                                -Dsonar.login=$SONARQUBE_TOKEN
                        '''
                    }
                }
            }
        }

        /* ------------------------ DEPENDENCY CHECK ------------------------ */
        stage('OWASP Dependency Check') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    sh 'mkdir -p dependency-check-report'

                    dependencyCheck additionalArguments: '''
                        --scan .
                        --format HTML
                        --format XML
                        --out dependency-check-report
                    ''', odcInstallation: 'dependency-check'
                }

                archiveArtifacts artifacts: 'dependency-check-report/*.*', allowEmptyArchive: true
            }
        }

        /* ------------------------ OWASP ZAP ------------------------ */
        stage('OWASP ZAP Scan') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    sh '''
                        mkdir -p zap-report
                        docker run --rm -u root \
                            -v $(pwd)/zap-report:/zap/wrk \
                            softwaresecurityproject/zap-stable \
                            zap-baseline.py \
                            -t http://localhost:8080 \
                            -r zap-report.html || true
                    '''
                }

                archiveArtifacts artifacts: 'zap-report/zap-report.html', allowEmptyArchive: true
            }
        }

    }

    /* ------------------------ SLACK NOTIFICATION ------------------------ */
    post {
        always {
            script {
                sh """
                    curl -X POST -H 'Content-type: application/json' \
                    --data '{"text":"Pipeline Completed ✔️"}' \
                    $SLACK_WEBHOOK_URL
                """
            }
        }
    }
}
