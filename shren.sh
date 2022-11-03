#!/usr/bin/env bash

###############################################################################
## Name:          shren.sh                                                   ##
## Description:   A bash [SH]ell script file and directory [REN]ame utility  ##
## Requirements:  Bash >= version 4                                          ##                                       ##
###############################################################################

set -o errexit
set -o pipefail
shopt -s nullglob

function show_usage() {
    cat <<EOF

Usage:

    shren [target directory] [-options]

    - The first parameter [target directory] is the base directory to search
    - Use an absolute path such as "/home/user/downloads" to avoid possible problems.
    - At least one option is required (rename use -r)
    - Add -p option to (p)review results ./shren [target directory] -pre

    - With -r both directory and file names be scanned and (r)enamed.
    - Example: "downloads/An Example Directory/Some--file.txt"
      Will be renamed to "downloads/an_example_directory/some_file.txt"

    [-options]

    -h   Display this usage screen
    -r   rename files and directories (as per above)
    --rd Only rename directories not files.
    --rf Only rename files not directories.
    -y   Remove all prompts when renaming individual directories or files.
    -e   Remove any empty directories found.
    -f   Remove/delete files with these names (seperate with spaces) ie. -k "file1.tmp file2.tmp"
    -t   Remove/delete files with these file extensions (seperate with spaces no '.' or '*') ie. -t "tmp temp"
    -o   Display configuration options and values.
    -s   Secure erase files with shred commands.
    -w   Set the overwrite times for shred. Default overwrite: 4
    -i   Ignore and allow restricted path names like '.' or '/'
    -m   Specifies max-depth (how many directories deep to go inside base directory)
         Example: shren /downloads -m 2 would include /downloads/** /downloads/**/**
    -l   Specifies a log file location. Default is: ${HOME}/shren_change.log
    -c   Preverve existing case of directory and file name. 
         Default: -r converts both file and directory names to lowercase.
    -p   Preview results. No changes to directories or files. Use with other options.
    -x   Remove these strings from names (seperate with spaces) ie. -x "fish dog abc 123"
    -z   Strip out underscores at end or renaming process (not before).
         Effectively this will remove spaces from names ie: this_file > thisfile
    
    --hyphens Use hyphens in names inplace of underscores.
    --nolog No logging of changes to log file.

EOF
exit
}

# Set colors for use in task terminal output functions
function message_colors() {
    if [[ -t 1 ]]; then
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        CYAN=$(printf '\033[36m')
        YELLOW=$(printf '\033[33m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[0m')
    else
        RED=""
        GREEN=""
        CYAN=""
        YELLOW=""
        BOLD=""
        RESET=""
    fi
}
# Init terminal message colors
message_colors

# Terminal message output formatting
# message() function displays formatted and coloured terminal messages.
# Usage example: message INFO "This is a information message"
function message() {
    local option=${1}
    local text=${2}
    case "${option}" in
        OLD) echo -e "[OLD] ${text}";;
        NEW) echo -e "[${CYAN}${BOLD}NEW${RESET}] ${CYAN}${text}${RESET}";;
        MATCH) echo -e "[${GREEN}MATCH${RESET}] ${text}";;
        EMPTY) echo -e "[${YELLOW}EMPTY${RESET}] ${text}";;
        RENAME) echo -e "[${GREEN}${BOLD}RENAMED${RESET}] ${GREEN}${text}${RESET}";;
        REMOVE) echo -e "[${RED}${BOLD}REMOVED${RESET}] ${RED}${text}${RESET}";;
        SHRED) echo -e "[${RED}${BOLD}SHREDDED${RESET}] ${RED}${text}${RESET}";;
        DONE) echo -e "[${GREEN}DONE${RESET}] ${GREEN}${text}${RESET}";;
        FAIL) echo -e "[${RED}${BOLD}FAIL${RESET}] ${text}";;
        SKIP) echo -e "[SKIP] ${text}";;
        OPTS) echo -e "[${YELLOW}OPTS${RESET}] ${text}";;
        INFO) echo -e "[${CYAN}INFO${RESET}] ${text}";;
        INFOFULL) echo -e "[${CYAN}INFO${RESET}] ${CYAN}${text}${RESET}";;
        WARN) echo -e "[${YELLOW}WARN${RESET}] ${text}";;
        WARNFULL) echo -e "[${YELLOW}WARN${RESET}] ${YELLOW}${text}${RESET}";;
        USER) echo -e "[${GREEN}USER${RESET}] ${text}";;
        DBUG) echo -e "[${YELLOW}${BOLD}DBUG${RESET}] ${YELLOW}${text}${RESET}";;
        *) echo -e "${text}";;
    esac
}


function add_log() {
    if [[ ${config[logging]} == true ]]; then
        logFile="${config[logPath]}"
        if [[ ! -f "${logFile}" ]]; then
cat << EOF >> "${logFile}"
##########################
## [SH][REN] CHANGE LOG ##
##########################

EOF
        fi
        local text=${1}
        if [[ ! -z ${text} ]]; then
            echo -e "${text}" >> "${logFile}"
        fi
    fi
}


function check_continue() {
    local response
    local question="${1}"
    while true; do
        read -r -p "[${GREEN}USER${RESET}] ${question} (y/N)? " response
        case "${response}" in
        [yY][eE][sS] | [yY])
            continued=true
            break
            ;;
        *)
            continued=false
            break
            ;;
        esac
    done
}


function count_results() {
    # Function to count up total directories and files to be processed.
    # Reset counters
    dirCount=0
    fileCount=0

    dirList=()
    dirListRev=()

    message INFOFULL "Scanning ${config[baseDir]}..."
    # Read find command results into dirList and fileList arrays
    IFS=$'\n' read -r -d '' -a dirList < <( find "${config[baseDir]}" -maxdepth ${config[maxDepth]} -type d && printf '\0' )
    IFS=$'\n' read -r -d '' -a fileList < <( find "${config[baseDir]}" -maxdepth ${config[maxDepth]} -type f && printf '\0' )

    dirTotal=${#dirList[*]}
    fileTotal=${#fileList[*]}
    
    if [[ dirTotal == 0 ]] && [[ fileTotal == 0 ]]; then
        message INFO "No directories or files found. Exiting"
        exit 0
    fi

    [[ ${dirTotal} == 1 ]] && dirWord="directory" || dirWord="directories"
    [[ ${fileTotal} == 1 ]] && fileWord="file" || fileWord="files"

    message INFO "Contains ${dirTotal} ${dirWord} and ${fileTotal} ${fileWord}..."
    echo
}


function check_array() {
    if ((! ${#@})); then
        exit 0
    fi
}


function show_options() {
    if [[ ${config[showOpts]} == true ]]; then
        for i in "${!config[@]}"; do
            case "${config[${i}]}" in
                "true") value="${GREEN}${config[${i}]}${RESET}";;
                "false") value="${YELLOW}${config[${i}]}${RESET}";;
                *) value="${CYAN}${config[${i}]}${RESET}";;
            esac
            message OPTS "${i}:${value}"
        done
    echo
fi
}


function remove_empty() {
    # Check array contains elements. Exit recursive search if no files or directories are found.
    for v in "${@}"; do
        if [[ -d "${v}" ]]; then
            local currentDir="${v}"
            while [[ -n "$(find "${currentDir}" -maxdepth 0 -type d -empty 2>/dev/null)" ]] && [[ "${currentDir}" != "${config[baseDir]}" ]]; do
                message EMPTY "Directory: ${currentDir}"
                    if [[ "${config[preview]}" == false ]]; then
                        if [[ "${config[confirm]}" == true ]]; then
                            check_continue "Remove this directory"
                        fi
                        if [[ "${continued}" == true ]] || [[ "${config[confirm]}" == false ]]; then
                            rmdir "${currentDir}" && message REMOVE "Directory: ${currentDir}" || message FAIL "Unable to remove empty directory: ${currentDir}"
                            add_log "rmdir \"${currentDir}\""
                        fi
                    fi
                    currentDir="${currentDir%/*}"
            done
        fi
    done
}

function remove_file() {
    file="${@}"
    if [[ "${config[preview]}" == false ]]; then
        if [[ "${config[confirm]}" == true ]]; then
            check_continue "Remove this file"
        fi
        if [[ "${continued}" == true ]] || [[ "${config[confirm]}" == false ]]; then
            if [[ "${config[useShred]}" == true ]]; then
                shred -uz -n ${config[overwrite]} "${file}" && message SHRED "File: ${file}" || message FAIL "Unable to remove file: ${file}"
                add_log "shred -uz -n ${config[overwrite]} \"${file}\""
            else 
                rm "${file}" && message REMOVE "File: ${file}" || message FAIL "Unable to remove file: ${file}"
                add_log "rm \"${file}\""
            fi
        fi
    fi
}

function match_file() {
    # Check array contains elements. Exit recursive search if no files or directories are found.
    for v in "${@}"; do
        if [[ -f "${v}" ]]; then
            for f in ${config[removeFile]}; do
                if [[ "${v}" == *"/${f}" ]]; then
                    message MATCH "File: ${f}"
                    message MATCH "${v}"
                    remove_file "${v}"
                fi          
            done
            for t in ${config[removeFileType]}; do
                if [[ "${v}" == *".${t}" ]]; then
                    message MATCH "File Type: *.${t}"
                    message MATCH "${v}"
                    remove_file "${v}"
                fi   
            done
        fi
    done
}


function clean_name() {
    # Do directory and file name changes with one lot of code (DRY).
    # Take in newName from other functions
    newName="${@}"
    if [[ "${config[useHyphens]}" == false ]]; then
        newName="${newName//-/_}"
    fi
    newName=$(echo "${newName}" | sed 's/[^a-zA-Z0-9.//_-]//g')

    # Check for any strings to be removed.
    if [[ ! -z ${config[removeString]} ]]; then
        for str in ${config[removeString]}; do
            newName="${newName//${str}/}"
        done
    fi

    # Fix when renaming results in strange combinations
    # Bad combinations where one hyphen should be left
    if [[ "${config[useHyphens]}" == true ]]; then
        local fixCombos="-- -_ _- .-"
        for c in ${fixCombos}; do
            while [[ "${newName}" == *"${c}"* ]]; do
                newName="${newName//${c}/-}"
            done
        done
    fi

    # Bad combinations where one underscore should be left
    local fixCombos="__ ._"
    for c in ${fixCombos}; do
        while [[ "${newName}" == *"${c}"* ]]; do
            newName="${newName//${c}/_}"
        done
    done

    # Bad combinations where one period should be left
    local fixCombos=".. _."
    for c in ${fixCombos}; do
        while [[ "${newName}" == *"${c}"* ]]; do
            newName="${newName//${c}/.}"
        done
    done

    if [[ "${config[lowerCase]}" == true ]]; then
        newName="${newName,,}"
    fi

    # Replace underscores with hyphens if true
    if [[ "${config[useHyphens]}" == true ]]; then
        while [[ "${newName}" == *"_"* ]]; do
            newName="${newName//_/-}"
        done
    fi

    # Strip out underscores if config[underscores]=true
    if [[ "${config[underscores]}" == false ]]; then
        while [[ "${newName}" == *"_"* ]]; do
            newName="${newName//_/}"
        done
    fi
    # Return modified newName through echo statement as bash does not support returns.
    echo ${newName}
}

function clean_and_rename() {
    # Check for directories to be renamed if config[filesOnly]=false
        message INFOFULL "Checking directory and file names..."
        for v in "${@}"; do
            if [[ -d "${v}" ]]; then
                echo
                message INFOFULL "Processing ${v}"
            if [[ "${config[filesOnly]}" == false ]]; then
                oldName="${v//${config[baseDir]}/}"
                newName="${oldName// /_}"
                newName="${newName//./_}"

                # Send newName to clean_name function for clean up
                newName=$(clean_name "${newName}")

                # Checks directory needs to be renamed. Renames and logs changes.
                if [[ "${oldName}" != "${newName}" ]]; then
                    message OLD "${config[baseDir]}${oldName}"
                    message NEW "${config[baseDir]}${newName}"
                    if [[ "${config[preview]}" == false ]]; then
                        if [[ "${config[confirm]}" == true ]]; then
                            check_continue "Rename this directory"
                        fi
                        if [[ "${continued}" == true ]] || [[ "${config[confirm]}" == false ]]; then
                            mv "${config[baseDir]}${oldName}" "${config[baseDir]}${newName}" && message RENAME "Directory: ${config[baseDir]}${newName}" || message FAIL "Unable to rename directory: ${config[baseDir]}${oldName}"
                            add_log "mv \"${config[baseDir]}${oldName}\" \"${config[baseDir]}${newName}\""
                        else
                            message SKIP "${v}${oldName}"
                        fi
                    fi
                else
                    message SKIP "${v}${oldName}"
                fi
            fi
            fi
        done
    # Check for files to be renamed if config[dirsOnly]=false
    if [[ "${config[dirsOnly]}" == false ]]; then
        for v in "${@}"; do
            if [[ -f "${v}" ]]; then
                oldName="${v//${config[baseDir]}\//}"
                fileName=${oldName##*/}
                subDir=${oldName//${fileName}}
                newName="${fileName// /_}"
                if [[ "${config[useHyphens]}" == false ]]; then
                    newName="${newName//-/_}"
                fi
                # Remove all by specified characters in sed command
                newName=$(echo "${newName}" | sed 's/[^a-zA-Z0-9.//_-]//g')
                
                # Use regEx patterns and attempt to detect file extension
                # Replaced all but required periods with underscores
                if [[ "${oldName}" =~ ^(.*)(\.[a-zA-Z]{2,4}\.[a-zA-Z0-9]{2,4})$ ]]; then
                    # Files ending in extension such as tar.gz
                    newName=$(echo "${newName}" | sed 's/\./\_/g; s/\(.*\)\_/\1\./; s/\(.*\)\_/\1\./')
                elif [[ "${oldName}" =~ ^(.*)(\.[a-zA-Z0-9]{1,4})$ ]]; then
                    # Files ending in extension from 1 to 4 characters in length
                    newName=$(echo "${newName}" | sed 's/\./\_/g; s/\(.*\)\_/\1\./')
                else
                    # If a file extension was not identified replace any periods with underscores
                    # There may be files which do not have an extension.
                    newName="${newName//./_}"
                fi
                # Send newName to clean_name function for clean up
                newName=$(clean_name "${newName}")

                # Checks file needs to be renamed. Renames and logs changes.
                if [[ "${fileName}" != "${newName}" ]]; then
                    message OLD "${config[baseDir]}/${subDir}${fileName}"
                    message NEW "${config[baseDir]}/${subDir}${newName}"
                    if [[ "${config[preview]}" == false ]]; then
                        if [[ "${config[confirm]}" == true ]]; then
                            check_continue "Rename this file"
                        fi
                        if [[ "${continued}" == true ]] || [[ "${config[confirm]}" == false ]]; then
                            mv "${config[baseDir]}/${oldName}" "${config[baseDir]}/${subDir}${newName}" && message RENAME "File: ${config[baseDir]}/${subDir}${newName}" || message FAIL "An error occurred renaming file: ${newName}"
                            add_log "mv \"${config[baseDir]}/${oldName}\" \"${config[baseDir]}/${subDir}${newName}\""
                        else 
                            message SKIP "${config[baseDir]}/${oldName}"
                        fi
                    fi
                else
                    message SKIP "${config[baseDir]}/${oldName}"
                fi
            fi
        done
    fi
}

function main() {
    echo -e "\n${GREEN}[SH][REN]${RESET}\n\n$(date)\n"
    # Configuration settings
    declare -A config
    config=(
        [baseDir]=""
        [logPath]="${HOME}/shren_change.log"
        [logging]=true
        [maxDepth]=10
        [lowerCase]=true
        [preview]=false
        [confirm]=true
        [filesOnly]=false
        [dirsOnly]=false
        [ignorePath]=false
        [showOpts]=false
        [removeFileType]=""
        [removeFile]=""
        [removeString]=""
        [overwrite]=4
        [showUsage]=false
        [useShred]=false
        [underscores]=true
        [useHyphens]=false
        [rename]=false
        [removeEmpty]=false
        [dateString]="$(date +"%Y%m%d%H%M%S")"
    )

    # Get command line options flags
    [[ "${1}" == "--help" ]] && show_usage
    [[ "${1}" == "--usage" ]] && show_usage

    allArgs=${@:2}
    shortArgs=${allArgs}

    # Process long arguments and return short arguments for getopts
    for arg in ${allArgs}; do
        case "${arg}" in
        --rd) config[dirsOnly]=true && config[rename]=true && shortArgs="${shortArgs//${arg}/}";;
        --rf) config[filesOnly]=true && config[rename]=true && shortArgs="${shortArgs//${arg}/}";;
        --hyphens) config[useHyphens]=true && shortArgs="${shortArgs//${arg}/}";;
        --nolog) config[logging]=false && shortArgs="${shortArgs//${arg}/}";;
        esac
    done

    # Get short -x command line arguments
    while getopts :l:m:f:t:w:x:hpcsuiorzeyl opts "${shortArgs}"
    do
        case "${opts}" in
            r) config[rename]=true;;
            l) config[logPath]=${OPTARG};;
            m) config[maxDepth]=${OPTARG};;
            c) config[lowerCase]=false;;
            f) config[removeFile]=${OPTARG};;
            t) config[removeFileType]=${OPTARG};;
            e) config[removeEmpty]=true;;
            s) config[useShred]=true;;
            w) config[overwrite]=${OPTARG};;
            p) config[preview]=true && config[confirm]=false;;
            h) config[showUsage]=true;;
            u) config[showUsage]=true;;
            i) config[ignorePath]=true;;
            o) config[showOpts]=true;;
            y) config[confirm]=false;;
            x) config[removeString]=${OPTARG};;
            z) config[underscores]=false;;
            # *) echo "Invalid command line switch specified: -${OPTARG}" && exit 1;;
        esac
    done

    # Restrict base path to prevent accidental renaming or deletion
    if [[ "${config[ignorePath]}" == false ]]; then
        disallowedPaths=". / ./ ../ ../.. ./.. ../../.."
        if [[ -z "${1}" ]]; then
            message WARN "No target/base directory specified: ${1}"
            message INFO "Type: $(basename "$0") -h or --help for usage options."
            exit       
        elif [[ ! -d "${1}" ]]; then
            message WARN "Invalid base directory specified: ${1}"
            message INFO "The directory path specified does not appear to exist."
            exit
        else
            for v in ${disallowedPaths}; do
                if [[ "${1}" == "${v}" ]]; then
                    message WARN "Disallowed root or similar base directory specified. Use an absolute directory path."
                    message INFO "Allow and ignore path warning using -i"
                    exit
                fi
            done
        fi
    fi
    
    # Set baseDir
    if [[ "${1:0-1}" == "/" ]]; then
        config[baseDir]="${1%?}"
    else
        config[baseDir]="${1}"
    fi

    # Check options
    [[ ${config[showUsage]} = true ]] && show_usage
    [[ ${config[showOpts]} = true ]] && show_options
    [[ ${config[preview]} = true ]] && message INFOFULL "RUNNING IN ${BOLD}PREVIEW MODE${RESET}...\n"

    # Count total directories and files based on depth and baseDir
    count_results

    [[ -z ${@:2} ]] && message INFO "No options selected. Type: $(basename "$0") -h or --help for usage options."

    # Do the work
    currentDirectory=${config[baseDir]}
    add_log "\n### ${config[dateString]}"
    add_log "### $(basename ${0}) ${config[baseDir]} ${allArgs}"
    for i in $(seq ${config[maxDepth]}); do
        currentDirectory+=/**
        check_array ${currentDirectory[@]}
        # Check files to be removed first
        if [[ ! -z "${config[removeFileType]}" ]] || [[ ! -z "${config[removeFile]}" ]]; then
            match_file ${currentDirectory[@]}
        fi
        # Check for empty directories
        [[ "${config[removeEmpty]}" == true ]] && remove_empty ${currentDirectory[@]}
        # Run clean and rename
        [[ "${config[rename]}" == true ]] && clean_and_rename ${currentDirectory[@]}
    done
}

main "${@}"
