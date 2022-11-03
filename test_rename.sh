#!/usr/bin/env bash

set -o errexit
set -o pipefail

main() {
    clear
    echo -e "\033[32m[SH][REN] TESTING FILE AND DIRECTORY RENAMING...\033[0m\n"
    testPath="${HOME}/shren_testing"
    rm -rf "${testPath}"
    echo -e "[\033[36mINFO\033[0m] Creating directories and files for shren script testing..."
    mkdir -p "${testPath}"
    mkdir -p "${testPath}/dir LeVeL O**N**E/D!IR... LE$%V%EL ___TW?O/DI%%%R--- L*E*V*E*L -----ThREe"
    mkdir -p "${testPath}/not_empty/empty_o@@ne/empty!!! two/empty####...three/empty&&& four"
    mkdir -p "${testPath}/not.empty.dot.one/not.empty.dot.two"
    touch "${testPath}/not.empty.dot.one/test-me1.txt"
    touch "${testPath}/not.empty.dot.one/not.empty.dot.two/test-me2.txt"
    touch "${testPath}/not_empty/a_file!!!#...in   not_empty.txt"
    touch "${testPath}/Te\$\$ST F#@#!ILe-👍- Zero %.png"
    touch "${testPath}/dir LeVeL O**N**E/Te\$\$\$ST F!ILe-- One %A001.js"
    touch "${testPath}/dir LeVeL O**N**E/catfish.png"
    touch "${testPath}/dir LeVeL O**N**E/bigdog.gif"
    touch "${testPath}/dir LeVeL O**N**E/TeST F!iLe-- One \$b002.json"
    touch "${testPath}/dir LeVeL O**N**E/TeST F!ile....One **c...003....bz1"
    touch "${testPath}/dir LeVeL O**N**E/D!IR... LE$%V%EL ___TW?O/Te##@S***!T   F!!!!😂😂😂IL###e -- Tw#@!o a.tar.gz"
    touch "${testPath}/dir LeVeL O**N**E/D!IR... LE$%V%EL ___TW?O/Te##@S**!T   F!!!!iL###e  Two b.jpeg"
    touch "${testPath}/dir LeVeL O**N**E/D!IR... LE$%V%EL ___TW?O/DI%%%R--- L*E*V*E*L -----ThREe/Test fi!!!!le three.txt"
    
    before=$(ls -RF "${testPath}")
    
    echo -e "[\033[36mINFO\033[0m] Running shren.sh on ${testPath}..."
    bash shren.sh ${testPath} -yer
    
    after=$(ls -RF "${testPath}")
    
    echo -e "\n[\033[36mINFO\033[0m] Test completed...\n"
    echo -e "[\033[36mINFO\033[0m] Compare the results...\n"
    echo -e "BEFORE:\n\n ${before}"
    echo -e "AFTER:\n\n ${after}"
}

main

