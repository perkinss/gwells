// Jenkinsfile (Scripted Pipeline)


import hudson.model.Result;
import jenkins.model.CauseOfInterruption.UserInterruption;
import org.kohsuke.github.*
import bcgov.OpenShiftHelper
import bcgov.GitHubHelper

def _stage(String name, Map context, Closure body) {
    def stageOpt =(context?.stages?:[:])[name]
    boolean isEnabled=(stageOpt == null || stageOpt == true)
    //echo "Stage - ${stage}"
    echo "Running Stage '${name}' - enabled:${isEnabled}"
    if (isEnabled){
        stage(name) {
            body()
        }
    }else{
        stage(name) {
            echo 'Skipping'
        }
    }
}

Map context = [
  'name': 'gwells',
  'uuid' : UUID.randomUUID().toString(),
  'env': [
      'dev':[:],
      'test':[:],
      'prod':['params':['_host':'']]
  ],
  'templates': [
      'build':[
          ['file':'openshift/postgresql.bc.json'],
          ['file':'openshift/backend.bc.json']
      ],
      'deployment':[
          ['file':'openshift/postgresql.dc.json',
              'params':[
                  'DATABASE_SERVICE_NAME':'gwells-pgsql${deploy.dcSuffix}',
                  'IMAGE_STREAM_NAMESPACE':'',
                  'IMAGE_STREAM_NAME':'gwells-postgresql${deploy.dcSuffix}',
                  'IMAGE_STREAM_VERSION':'${deploy.envName}',
                  'POSTGRESQL_DATABASE':'gwells'
              ]
          ],
          ['file':'openshift/backend.dc.json', 'params':['HOST':'${env[DEPLOY_ENV_NAME]?.params?.host?:""}']]
      ]
  ],
  stages:[
    'Build': true,
    'Unit Test': true,
    'Code Quality': true,
    'Readiness - DEV': true,
    'Full Test - DEV': true
  ]
]


properties([
        buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')),
        durabilityHint('MAX_SURVIVABILITY'),
        parameters([string(defaultValue: '', description: '', name: 'run_stages')])
])

String uuid = UUID.randomUUID().toString()

stage('Prepare') {
    abortAllPreviousBuildInProgress(currentBuild)
    echo "BRANCH_NAME=${env.BRANCH_NAME}\nCHANGE_ID=${env.CHANGE_ID}\nCHANGE_TARGET=${env.CHANGE_TARGET}\nBUILD_URL=${env.BUILD_URL}"
}

/*
def label = "mypod-${UUID.randomUUID().toString()}"
podTemplate(label: label, serviceAccount: 'jenkins', cloud: 'openshift', containers: [
    containerTemplate(name: 'maven', image: 'registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7:v3.6.173.0.112-3', ttyEnabled: true, command: '/bin/sh'),
  ],volumes: [
    emptyDirVolume(mountPath: '/tmp/gwells-app', memory: false)
  ]
) {
    node(label) {
        stage('Get a Maven project') {
            sh 'pwd'
            container('maven') {
                stage('Build a Maven project') {
                    sh 'pwd'
                    sh 'env'
                    sh script: 'bash -c "which mvn"', returnStatus: true
                    sh script: '{ set +x; } 2>/dev/null && source /usr/local/bin/scl_enable && mvn -v', returnStatus: true

                    input(message: "Continue?")
                }
            }
        }
    }
}
*/


    _stage('Build', context) {
        node('master') {
            checkout scm
            new OpenShiftHelper().build(this, context)
            if ("master".equalsIgnoreCase(env.CHANGE_TARGET)) {
                new OpenShiftHelper().prepareForCD(this, context)
            }
        }
    } //end stage


        if (1 == 2) {
        stage('Unit Test 1') {
            String nodeLabel = UUID.randomUUID().toString()
            podTemplate(label: nodeLabel, serviceAccount: 'jenkins', cloud: 'openshift', containers: [
                containerTemplate(name: 'test', image: "172.50.0.2:5000/csnr-devops-lab-tools/gwells-python-test${context.buildNameSuffix}:${context.buildEnvName}", ttyEnabled: true, command: 'container-entrypoint', args:'/bin/sh'),
                containerTemplate(name: 'app', image: "172.50.0.2:5000/csnr-devops-lab-tools/gwells${context.buildNameSuffix}:${context.buildEnvName}", ttyEnabled: true, command: '/bin/sh')
              ],volumes: [
                emptyDirVolume(mountPath: '/tmp/gwells-app', memory: false)
              ]
            ) {
                node(nodeLabel) {
                    stage('Get a Maven project') {
                        sh 'pwd'
                        container('app') {
                            //sh script: 'env', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null  && python --version', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null  && pip --version', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null  && npm --version', returnStatus: true
                            sh script: 'cp -r /opt/app-root/src /tmp/gwells-app/', returnStatus: true
                            sh script: 'ls -la /opt/app-root ; ls -la /opt/app-root/src', returnStatus: true

                            //input(message: "Continue?")
                        }
                        container('test') {
                            //sh script: 'env', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null  && python --version', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null  && pip --version', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null  && npm --version', returnStatus: true
                            sh script: 'rm -rf /opt/app-root/src', returnStatus: true
                            sh script: 'cp -r /tmp/gwells-app/src /opt/app-root/ ', returnStatus: true
                            //&& source /usr/local/bin/scl_enable
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null && cd /opt/app-root/src/ && pip install -r requirements.txt', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null && cd /opt/app-root/src/ && python manage.py collectstatic && python manage.py migrate', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null && cd /opt/app-root/src/ && export ENABLE_DATA_ENTRY="True" && python manage.py test -c nose.cfg', returnStatus: true
                            sh script: '{ source /opt/app-root/etc/scl_enable; source /opt/app-root/bin/activate; } 2>/dev/null && cd /opt/app-root/src/frontend && npm test', returnStatus: true
                            input(message: "Continue?")
                        }
                    }
                }
            }
        } //end stage
        }

        _stage('Unit Test', context) {
            podTemplate(label: "pythonnodejs-${uuid}", name: "pythonnodejs-${uuid}", serviceAccount: 'jenkins', cloud: 'openshift', containers: [
            containerTemplate(
                name: 'jnlp',
                image: '172.50.0.2:5000/openshift/jenkins-slave-python3nodejs',
                resourceRequestCpu: '500m',
                resourceLimitCpu: '1000m',
                resourceRequestMemory: '1Gi',
                resourceLimitMemory: '4Gi',
                workingDir: '/tmp',
                command: '',
                args: '${computer.jnlpmac} ${computer.name}'
            )
            ])
            {
                node("pythonnodejs-${uuid}") {
                    checkout scm
                    dir ('app'){
                        try {
                            sh 'pip install --upgrade pip'
                            sh 'pip install -r requirements.txt'
                            sh 'cd frontend && npm install'
                            sh 'cd frontend && npm run build'
                            sh 'python manage.py collectstatic && python manage.py migrate'
                            sh 'export ENABLE_DATA_ENTRY="True" && python manage.py test -c nose.cfg'
                            sh 'cd frontend && npm test'
                        }
                        finally {
                            archiveArtifacts allowEmptyArchive: true, artifacts: 'frontend/test/unit/**/*'
                            stash includes: 'nosetests.xml,coverage.xml', name: 'coverage'
                            stash includes: 'frontend/test/unit/coverage/clover.xml', name: 'nodecoverage'
                            stash includes: 'frontend/junit.xml', name: 'nodejunit'
                            junit 'nosetests.xml,frontend/junit.xml'
                            publishHTML (target: [
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                keepAll: true,
                                reportDir: 'frontend/test/unit/coverage/lcov-report/',
                                reportFiles: 'index.html',
                                reportName: "Node Coverage Report"
                            ])
                        }
                    }
                } //end node

            }// end podTemplate
        } //end stage


        _stage('Code Quality', context) {
            podTemplate(
                name: "sonar-runner${uuid}",
                label: "sonar-runner${uuid}",
                serviceAccount: 'jenkins',
                cloud: 'openshift',
                containers:[
                    containerTemplate(
                        name: 'jnlp',
                        resourceRequestMemory: '1Gi',
                        resourceLimitMemory: '4Gi',
                        resourceRequestCpu: '500m',
                        resourceLimitCpu: '4000m',
                        image: 'registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7:v3.7',
                        workingDir: '/tmp',
                        args: '${computer.jnlpmac} ${computer.name}'
                    )
                ]
            ){
                node("sonar-runner${uuid}") {
                    //the checkout is mandatory, otherwise code quality check would fail
                    echo "checking out source"
                    echo "Build: ${BUILD_ID}"
                    checkout scm

                    String SONARQUBE_URL = 'https://sonarqube-moe-gwells-tools.pathfinder.gov.bc.ca'
                    echo "SONARQUBE_URL: ${SONARQUBE_URL}"
                    dir('app') {
                        unstash 'nodejunit'
                        unstash 'nodecoverage'
                    }
                    dir('sonar-runner') {
                        unstash 'coverage'
                        sh returnStdout: true, script: "./gradlew sonarqube -Dsonar.host.url=${SONARQUBE_URL} -Dsonar.verbose=true --stacktrace --info  -Dsonar.sources=.."
                    }
                }
            }

        } //end stage



    def isCI = !"master".equalsIgnoreCase(env.CHANGE_TARGET)
    def isCD = "master".equalsIgnoreCase(env.CHANGE_TARGET)

    for(String envKeyName: context.env.keySet() as String[]){
        String stageDeployName=envKeyName.toUpperCase()

        if ("DEV".equalsIgnoreCase(stageDeployName) || isCD) {
            _stage("Readiness - ${stageDeployName}", context) {
                node('master') {
                    new OpenShiftHelper().waitUntilEnvironmentIsReady(this, context, envKeyName)
                }
            }
        }

        if (!"DEV".equalsIgnoreCase(stageDeployName) && isCD){
            stage("Approve - ${stageDeployName}") {
                def inputResponse = input(id: "deploy_${stageDeployName.toLowerCase()}", message: "Deploy to ${stageDeployName}?", ok: 'Approve', submitterParameter: 'approved_by')
                //echo "inputResponse:${inputResponse}"
                GitHubHelper.getPullRequest(this).comment("User '${inputResponse}' has approved deployment to '${stageDeployName}'")
            }
        }

        if ("DEV".equalsIgnoreCase(stageDeployName) || isCD){
            _stage("Deploy - ${stageDeployName}", context) {
                node('master') {
                    new OpenShiftHelper().deploy(this, context, envKeyName)
                }
            }
        }


        if (1 == 2 && "DEV".equalsIgnoreCase(stageDeployName)){
            String baseURL = context.deployments[envKeyName].environmentUrl.substring(0, context.deployments[envKeyName].environmentUrl.indexOf('/', 8) + 1)
            stage('API Test') {
                podTemplate(label: 'nodejs', name: 'nodejs', serviceAccount: 'jenkins', cloud: 'openshift', containers: [
                  containerTemplate(
                    name: 'jnlp',
                    image: 'registry.access.redhat.com/openshift3/jenkins-slave-nodejs-rhel7',
                    resourceRequestCpu: '500m',
                    resourceLimitCpu: '1000m',
                    resourceRequestMemory: '1Gi',
                    resourceLimitMemory: '4Gi',
                    workingDir: '/tmp',
                    command: '',
                    args: '${computer.jnlpmac} ${computer.name}',
                    envVars: [
                        envVar(key:'BASEURL', value: baseURL),
                        secretEnvVar(key: 'GWELLS_API_TEST_USER', secretName: 'apitest-secrets', secretKey: 'username'),
                        secretEnvVar(key: 'GWELLS_API_TEST_PASSWORD', secretName: 'apitest-secrets', secretKey: 'password'),
                        secretEnvVar(key: 'GWELLS_API_TEST_AUTH_SERVER', secretName: 'apitest-secrets', secretKey: 'auth_server'),
                        secretEnvVar(key: 'GWELLS_API_TEST_CLIENT_ID', secretName: 'apitest-secrets', secretKey: 'client_id'),
                        secretEnvVar(key: 'GWELLS_API_TEST_CLIENT_SECRET', secretName: 'apitest-secrets', secretKey: 'client_secret'),
                       ]
                  )
                ])
                {
                    node('nodejs') {
                    //the checkout is mandatory, otherwise functional test would fail
                        echo "checking out source"
                        echo "Build: ${BUILD_ID}"
                        echo "baseURL: ${baseURL}"
                        checkout scm
                        dir('api-tests') {
                            sh 'npm install -g newman'
                            try {
                                sh 'newman run ./registries_api_tests.json --global-var test_user=$GWELLS_API_TEST_USER --global-var test_password=$GWELLS_API_TEST_PASSWORD --global-var base_url="${BASEURL}/gwells" --global-var auth_server=$GWELLS_API_TEST_AUTH_SERVER --global-var client_id=$GWELLS_API_TEST_CLIENT_ID --global-var client_secret=$GWELLS_API_TEST_CLIENT_SECRET -r cli,junit,html;'
                            } finally {
                                    junit 'newman/*.xml'
                                    publishHTML (target: [
                                                allowMissing: false,
                                                alwaysLinkToLastBuild: false,
                                                keepAll: true,
                                                reportDir: 'newman',
                                                reportFiles: 'newman*.html',
                                                reportName: "API Test Report"
                                            ])
                                    stash includes: 'newman/*.xml', name: 'api-tests'
                            }
                        } // end dir
                    } //end node
                } //end podTemplate
            } //end stage
        }

        if ("DEV".equalsIgnoreCase(stageDeployName) || isCD){
            String baseURL = context.deployments[envKeyName].environmentUrl.substring(0, context.deployments[envKeyName].environmentUrl.indexOf('/', 8) + 1)
            String testStageName="DEV".equalsIgnoreCase(stageDeployName)?"Full Test - DEV":"Smoke Test - ${stageDeployName}"
            _stage(testStageName, context){
                if ("DEV".equalsIgnoreCase(stageDeployName)){
                    node('master'){
                        String podName=null
                        openshift.withProject('csnr-devops-lab-deploy'){
                            podName=openshift.selector('pod', ['deploymentconfig':"gwells-dev-pr-1"]).objects()[0].metadata.name
                        }
                        sh "oc exec '${podName}' -n 'csnr-devops-lab-deploy' -- bash -c 'cd /opt/app-root/src && pwd && python manage.py loaddata wells registries'"
                    }
                }
                podTemplate(label: "bddstack-${uuid}", name: "bddstack-${uuid}", serviceAccount: 'jenkins', cloud: 'openshift', containers: [
                  containerTemplate(
                    name: 'jnlp',
                    image: '172.50.0.2:5000/openshift/jenkins-slave-bddstack',
                    resourceRequestCpu: '500m',
                    resourceLimitCpu: '4000m',
                    resourceRequestMemory: '1Gi',
                    resourceLimitMemory: '4Gi',
                    workingDir: '/home/jenkins',
                    command: '',
                    args: '${computer.jnlpmac} ${computer.name}',
                    envVars: [
                        envVar(key:'BASEURL', value: baseURL)
                       ]
                  )
                ])
                {
                    node("bddstack-${uuid}") {
                        //the checkout is mandatory, otherwise functional test would fail
                        echo "checking out source"
                        echo "Build: ${BUILD_ID}"
                        echo "baseURL: ${baseURL}"
                        checkout scm
                        dir('functional-tests/build/test-results') {
                            sh 'echo "BASEURL=${BASEURL}"'
                            unstash 'coverage'
                            sh 'rm coverage.xml'
                            unstash 'nodejunit'
                            }
                        //dir('app') {
                        //    sh 'python manage.py loaddata wells registries'
                        //}
                        dir('functional-tests') {
                            try {

                                if ("DEV".equalsIgnoreCase(stageDeployName)){
                                    sh './gradlew chromeHeadlessTest'
                                }else{
                                    sh './gradlew -DchromeHeadlessTest.single=WellDetails chromeHeadlessTest'
                                }
                            } finally {
                                    archiveArtifacts allowEmptyArchive: true, artifacts: 'build/reports/geb/**/*'
                                    junit 'build/test-results/**/*.xml'
                                    publishHTML (target: [
                                                allowMissing: false,
                                                alwaysLinkToLastBuild: false,
                                                keepAll: true,
                                                reportDir: 'build/reports/spock',
                                                reportFiles: 'index.html',
                                                reportName: "Test: BDD Spock Report"
                                            ])
                                    publishHTML (target: [
                                                allowMissing: false,
                                                alwaysLinkToLastBuild: false,
                                                keepAll: true,
                                                reportDir: 'build/reports/tests/chromeHeadlessTest',
                                                reportFiles: 'index.html',
                                                reportName: "Test: Full Test Report"
                                            ])
                                //todo: install perf report plugin.
                                //perfReport compareBuildPrevious: true, excludeResponseTime: true, ignoreFailedBuilds: true, ignoreUnstableBuilds: true, modeEvaluation: true, modePerformancePerTestCase: true, percentiles: '0,50,90,100', relativeFailedThresholdNegative: 80.0, relativeFailedThresholdPositive: 20.0, relativeUnstableThresholdNegative: 50.0, relativeUnstableThresholdPositive: 50.0, sourceDataFiles: 'build/test-results/**/*.xml'
                            }
                        }
                    } //end node
                } //end podTemplate
            }
        } //end if
    } // end for


stage('Cleanup') {
    def inputResponse=input(id: 'close_pr', message: "Ready to Accept/Merge, and Close pull-request #${env.CHANGE_ID}?", ok: 'Yes', submitter: 'authenticated', submitterParameter: 'approver')
    echo "inputResponse:${inputResponse}"

    new OpenShiftHelper().cleanup(this, context)
    GitHubHelper.mergeAndClosePullRequest(this)
}
