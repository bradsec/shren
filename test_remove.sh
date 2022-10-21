#!/usr/bin/env bash

set -o errexit
set -o pipefail

main() {
    clear
    echo -e "\033[32m[SH][REN] TESTING FILE AND EMPTY DIRECTORY REMOVAL\033[0m\n"
    testPath="${HOME}/shren_testing"
    rm -rf "${testPath}"
    echo -e "[\033[36mINFO\033[0m] Creating directories and files for shren script testing..."
    mkdir -p "${testPath}"
    mkdir -p "${testPath}/directory one/directory two"
    mkdir -p "${testPath}/not emp@@@ty one/empty two"
    mkdir -p "${testPath}/an empty one"
    touch "${testPath}/directory one/directory two/this file in two.tar.gz"
    touch "${testPath}/directory one/removeme1.zip"
    touch "${testPath}/directory one/dontremoveme1.zip"
    touch "${testPath}/directory one/removeme1not.zip"
    touch "${testPath}/directory one/removeme2.zip"
    touch "${testPath}/not emp@@@ty one/this is a file in n!!ot empty one.txt"
    touch "${testPath}/not emp@@@ty one/this is a temp file 001.tmp"
    touch "${testPath}/not emp@@@ty one/this is a temp file 002.temp"
    touch "${testPath}/not emp@@@ty one/this is a temp file 003.tmp"
    touch "${testPath}/not emp@@@ty one/this is a temp file 003nottmp"
    touch "${testPath}/not emp@@@ty one/this is a temp file 003.nottmp"
    touch "${testPath}/not emp@@@ty one/this is a temp file 003.tmp.not"
    touch "${testPath}/directory one/this i###s a file in dir two.json"
    
    echo -e "[\033[36mINFO\033[0m] Running shren.sh on ${testPath}..."
    bash shren.sh ${testPath} -ye -f "removeme1.zip removeme2.zip" -t "tmp temp"
    
    echo -e "\n[\033[36mINFO\033[0m] Test completed...\n"
}

main

