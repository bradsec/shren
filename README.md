# [SH][REN]

**A ba[SH] shell script to batch clean and [REN]ame directories and files**

*** Tested on Debian linux and macOS BigSur ***

## Purpose / Features

- Standardize file and directory names.
- Clean up non-standard or corrupted file paths.
- Batch rename and clean up messy download or document directories.
- Remove non-alphanumeric characters from directory and file names.
- Remove whitespace. Single spaces and periods are replaced with underscores.
- Remove specific strings/text from directory or file names.
- Search and remove specific file names or file types.
- Recursive directory search with custom depth.
- No external programs required (uses built-in system commands).

## Requirements

- Script requires bash version >= 4
- macOS releases may be running bash version 3
```terminal
# Fix/upgrade bash version on macOS using homebrew

# Check version
bash --version

# To update using homebrew
brew install bash

# Restart terminal or run 
exec bash
```


## Installation

```terminal
# 1. Clone repo or manually download the script
# 2. Copy script without .sh extension to a directory in the ${PATH} variable such /usr/local/sbin
# 3. Make script executable

cd ~
git clone https://github.com/bradsec/shren.git
cd shren

# Copy script to a directory in the user $PATH such as /usr/sbin or /usr/local/sbin
# .sh extension can be omitted when copied so command can be used as shren not shren.sh

sudo cp shren.sh /usr/local/sbin/shren

# Make script readable and executable
sudo chmod 755 /usr/local/sbin/shren
```

## Usage

```terminal
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
```
## Testing
**Two test script files included:**
1) `test_rename.sh` 
    - runs a test of file and directory renaming including names with special characters, spaces and emojis.
2) `test_removal.sh`
    - runs a test of file type and name removal along with empty directory removal.

### Example Results from `test_rename.sh`

Command used: `bash shren.sh ${testPath} -yer` 

```terminal
BEFORE:

 /shren_testing:
dir LeVeL O**N**E/
not_empty/
not.empty.dot.one/
Te$$ST F#@#!ILe-👍- Zero %.png

/shren_testing/dir LeVeL O**N**E:
bigdog.gif
catfish.png
D!IR... LE$%V%EL ___TW?O/
Te$$$ST F!ILe-- One %A001.js
TeST F!iLe-- One $b002.json
TeST F!ile....One **c...003....bz1

/shren_testing/dir LeVeL O**N**E/D!IR... LE$%V%EL ___TW?O:
DI%%%R--- L*E*V*E*L -----ThREe/
Te##@S***!T   F!!!!😂😂😂IL###e -- Tw#@!o a.tar.gz
Te##@S**!T   F!!!!iL###e  Two b.jpeg

/shren_testing/dir LeVeL O**N**E/D!IR... LE$%V%EL ___TW?O/DI%%%R--- L*E*V*E*L -----ThREe:
Test fi!!!!le three.txt

/shren_testing/not_empty:
a_file!!!#...in   not_empty.txt
empty_o@@ne/

/shren_testing/not_empty/empty_o@@ne:
empty!!! two/

/shren_testing/not_empty/empty_o@@ne/empty!!! two:
empty####...three/

/shren_testing/not_empty/empty_o@@ne/empty!!! two/empty####...three:
empty&&& four/

/shren_testing/not_empty/empty_o@@ne/empty!!! two/empty####...three/empty&&& four:

/shren_testing/not.empty.dot.one:
not.empty.dot.two/
test-me1.txt

/shren_testing/not.empty.dot.one/not.empty.dot.two:
test-me2.txt
```
```terminal
AFTER:


 /shren_testing:
dir_level_one/
not_empty/
not_empty_dot_one/
test_file_zero.png

/shren_testing/dir_level_one:
bigdog.gif
catfish.png
dir_level_two/
test_file_one_a001.js
test_file_one_b002.json
test_file_one_c_003.bz1

/shren_testing/dir_level_one/dir_level_two:
dir_level_three/
test_file_two_a.tar.gz
test_file_two_b.jpeg

/shren_testing/dir_level_one/dir_level_two/dir_level_three:
test_file_three.txt

/shren_testing/not_empty:
a_file_in_not_empty.txt

/shren_testing/not_empty_dot_one:
not_empty_dot_two/
test_me1.txt

/shren_testing/not_empty_dot_one/not_empty_dot_two:
test_me2.txt

```

### Example Results from `test_remove.sh`

Command used: `bash shren.sh ${testPath} -ye -f "removeme1.zip" -t "tmp temp 001"` 

```terminal
[SH][REN] TESTING FILE AND EMPTY DIRECTORY REMOVAL

[EMPTY] Dir: /shren_testing/an empty one
[REMOVED] Dir: /shren_testing/an empty one
[MATCH] File: removeme1.zip
[MATCH] /shren_testing/directory one/removeme1.zip
[REMOVED] File: /shren_testing/directory one/removeme1.zip
[MATCH] File Type: *.tmp
[MATCH] /shren_testing/not emp@@@ty one/this is a temp file 001.tmp
[REMOVED] File: /shren_testing/not emp@@@ty one/this is a temp file 001.tmp
[MATCH] File Type: *.tmp
[MATCH] /shren_testing/not emp@@@ty one/this is a temp file 002.tmp
[REMOVED] File: /shren_testing/not emp@@@ty one/this is a temp file 002.tmp
[MATCH] File Type: *.tmp
[MATCH] /shren_testing/not emp@@@ty one/this is a temp file 003.tmp
[REMOVED] File: /shren_testing/not emp@@@ty one/this is a temp file 003.tmp
[EMPTY] Dir: /shren_testing/not emp@@@ty one/empty two
[REMOVED] Dir: /shren_testing/not emp@@@ty one/empty two
```