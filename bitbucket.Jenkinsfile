#!/usr/bin/env groovy

outputImages = [
    "bsb002_uboot.bin",
    "kernel.bin",
    "root.bin",
    "overlay.bin",
];

productFactoryDir = 'bridge/build/bsb002/release/product/factory/bsb002';

def printStep(message) {
    print("===== ${message} =====")
}

def archiveResults() {
    printStep("archiving ${outputImages}")
    for(image in outputImages) {
        archiveArtifacts artifacts: "${productFactoryDir}/${image}", fingerprint: true
    }
}

def runInNetworkDeniedJail(args) {
    sh "firejail --force --noprofile --net=none ${args}"
}

def buildWithNoNetworking() {
    printStep("build with no networking")
    runInNetworkDeniedJail("make -j4")
}

stage('test') {
    node('docker_BB') {
        sh "echo \"===== RUNNING AS `whoami`@`hostname` IN `pwd` =====\""

        deleteDir()
        checkout scm
        buildWithNoNetworking()
        archiveResults()
    }
}

