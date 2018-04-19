import hudson.model.Result;
import jenkins.model.CauseOfInterruption.UserInterruption;
import org.kohsuke.github.*
import bcgov.OpenShiftHelper
import bcgov.GitHubHelper

Map context = [
  'name': 'gwells',
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
  ]
]


properties([
        buildDiscarder(logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '10')),
        durabilityHint('MAX_SURVIVABILITY'),
        parameters([string(defaultValue: '', description: '', name: 'run_stages')])
])


stage('Prepare') {
    abortAllPreviousBuildInProgress(currentBuild)
    echo "BRANCH_NAME=${env.BRANCH_NAME}\nCHANGE_ID=${env.CHANGE_ID}\nCHANGE_TARGET=${env.CHANGE_TARGET}\nBUILD_URL=${env.BUILD_URL}"
}

stage('Build') {
    node('master') {
        checkout scm
        new OpenShiftHelper().build(this, context)
        if ("master".equalsIgnoreCase(env.CHANGE_TARGET)) {
            new OpenShiftHelper().prepareForCD(this, context)
        }
    }
}

stage('Unit Test') {
    podTemplate(
        label: 'pythonnodejs',
        name: 'pythonnodejs',
        serviceAccount: 'jenkins',
        cloud: 'openshift',
        containers: [
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
        ]
    ){
        node('pythonnodejs') {
            checkout scm
            dir('app'){
                try {
                    sh 'pip install --upgrade pip && pip install -r requirements.txt'
                    sh 'cd frontend && npm install && npm run build && cd ..'
                    sh 'python manage.py collectstatic && python manage.py migrate'
                    sh 'export ENABLE_DATA_ENTRY="True" && python manage.py test -c nose.cfg'
                    sh 'cd frontend && npm test && cd ..'
                }
                finally {
                    archiveArtifacts allowEmptyArchive: true, artifacts: 'frontend/test/unit/**/*'
                    stash includes: 'nosetests.xml,coverage.xml', name: 'coverage'
                    stash includes: 'frontend/test/unit/coverage/clover.xml', name: 'nodecoverage'
                    stash includes: 'frontend/junit.xml', name: 'nodejunit'
                    junit 'nosetests.xml,frontend/junit.xml'
                    publishHTML (
                        target: [
                            allowMissing: false,
                            alwaysLinkToLastBuild: false,
                            keepAll: true,
                            reportDir: 'frontend/test/unit/coverage/lcov-report/',
                            reportFiles: 'index.html',
                            reportName: "Node Coverage Report"
                        ]
                    )
                }
            }
        }
    } //end podTemplate
} //end stage

for(String envKeyName: context.env.keySet() as String[]){
    String stageDeployName=envKeyName.toUpperCase()

    if ("DEV".equalsIgnoreCase(stageDeployName) || "master".equalsIgnoreCase(env.CHANGE_TARGET)) {
        stage("Readiness - ${stageDeployName}") {
            node('master') {
                new OpenShiftHelper().waitUntilEnvironmentIsReady(this, context, envKeyName)
            }
        }
    }

    if (!"DEV".equalsIgnoreCase(stageDeployName) && "master".equalsIgnoreCase(env.CHANGE_TARGET)){
        stage("Approve - ${stageDeployName}") {
            def inputResponse = input(id: "deploy_${stageDeployName.toLowerCase()}", message: "Deploy to ${stageDeployName}?", ok: 'Approve', submitterParameter: 'approved_by')
            //echo "inputResponse:${inputResponse}"
            GitHubHelper.getPullRequest(this).comment("User '${inputResponse}' has approved deployment to '${stageDeployName}'")
        }
    }

    if ("DEV".equalsIgnoreCase(stageDeployName) || "master".equalsIgnoreCase(env.CHANGE_TARGET)){
        stage("Deploy - ${stageDeployName}") {
            node('master') {
                new OpenShiftHelper().deploy(this, context, envKeyName)
            }
        }
    }

    podTemplate(label: 'bddstack', name: 'bddstack', serviceAccount: 'jenkins', cloud: 'openshift', containers: [
      containerTemplate(
        name: 'jnlp',
        image: '172.50.0.2:5000/openshift/jenkins-slave-bddstack',
        resourceRequestCpu: '500m',
        resourceLimitCpu: '1000m',
        resourceRequestMemory: '1Gi',
        resourceLimitMemory: '4Gi',
        workingDir: '/home/jenkins',
        command: '',
        args: '${computer.jnlpmac} ${computer.name}',
        envVars: [
            envVar(key:'BASEURL', value: context.deployments[envKeyName].environmentUrl.substring(0, context.deployments[envKeyName].environmentUrl.indexOf('/', 8) + 1))
           ]
      )
    ])
    {
        stage("Smoke Test - ${stageDeployName}") {
            node('bddstack') {
                //the checkout is mandatory, otherwise functional test would fail
                echo "checking out source"
                echo "Build: ${BUILD_ID}"
                checkout scm
                dir('functional-tests/build/test-results') {
                    sh 'echo "BASEURL=${BASEURL}"'
                    unstash 'coverage'
                    sh 'rm coverage.xml'
                    unstash 'nodejunit'
                    }
                dir('functional-tests') {
                    try {
                            sh './gradlew -DchromeHeadlessTest.single=WellDetails chromeHeadlessTest'
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
            }
        } // end stage
    } //end podTemplate

}

stage('Cleanup') {
    def inputResponse=input(id: 'close_pr', message: "Ready to Accept/Merge, and Close pull-request #${env.CHANGE_ID}?", ok: 'Yes', submitter: 'authenticated', submitterParameter: 'approver')
    echo "inputResponse:${inputResponse}"

    new OpenShiftHelper().cleanup(this, context)
    GitHubHelper.mergeAndClosePullRequest(this)
}
