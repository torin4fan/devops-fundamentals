#!/bin/bash

generateFile() {
    local file=users.db

    if ! [[ -f "$file" ]]; then
        touch $file
        echo "file $file was created"
    fi
}

showHelp() {
    echo -e "\033[1mUsage:\033[0m"
    echo -e "  db.sh [command] [options]"
    echo ""
    echo -e "\033[1mCommands:\033[0m"
    echo -e "  \033[32madd\033[0m              Adds a new user to the database"
    echo -e "  \033[32mlist\033[0m             Lists all users in the database"
    echo -e "  \033[32mfind <username>\033[0m  Finds a user by username"
    echo -e "  \033[32mbackup\033[0m           Creates a backup of the current database"
    echo -e "  \033[32mrestore\033[0m          Restores the database from the last backup"
    echo ""
    echo -e "\033[1mOptions:\033[0m"
    echo -e "  \033[32m--inverse\033[0m        Prints the list in reverse order (from bottom to top)"
    exit 0
}

checkLatinValid() {
    read -p "$1" info
    until [[ $info =~ ^[a-zA-Z]+$ ]]; do
            read -p "$info" username
    done
    echo "$info"
}

addUser() {
    local username=$(checkLatinValid "add username (Latin letters only): ")
    local role=$(checkLatinValid "add role (Latin letters only): ")
    echo "$username, $role" >> users.db
}

createBackup () {
    cp users.db "$(date)-users.db.backup"
}

restoreBackup () {
    local backupFile=$(ls -t *-users.db.backup 2>/dev/null | head -1)

    if [[ -z $backupFile ]]; then
        echo "No backup file found"
    else
        cp "$backupFile" users.db
        echo "Restored backup file: $backupFile"
    fi
}

findUser () {
    read -p "Enter a username: " username

    if [[ "$(grep -i "^$username," users.db)" ]]; then
        echo "$(grep -i "^$username," users.db)"
    else
        echo "User not found"
    fi
}

showUsersList () {
    if [ ! -f "users.db" ]; then
        echo "users.db not found"
        exit 1
    fi

    if [[ "$1" == "--inverse" ]]; then
        awk -F "," '{a[NR]=$0}END{for(i=NR;i>0;i--)print i". "a[i]}' users.db
    else
        awk -F "," '{printf "%d. %s, %s\n", NR, $1, $2}' users.db
    fi
}

if [[ $# > 0 && $1 != 'help' ]]; then
    generateFile
else
    showHelp
fi

case $1 in
    add) addUser;;
    backup) createBackup;;
    restore) restoreBackup;;
    find) findUser;;
    list) showUsersList $2;;
esac