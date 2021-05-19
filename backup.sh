#!/bin/bash
#data
SERVER_HOST="example.com"
SERVER_PORT="22"
USER="doomster"
DB_USER="doomster"
DB_PASSWORD="123456"
REMOTE_FILES_PATH="/var/www/html"
TEMP_FOLDER="~/backups_temp" 
LOCAL_BACKUP="/mnt/backups"

if [ $# -eq 0 ]
then
        echo "Missing options!"
        echo "(run $0 -h for help)"
        echo ""
        exit 0
fi

ECHO="false"

while getopts "dfch" OPTION; do
        case $OPTION in

                d)
                        TYPE="database"
                        ;;
                f)
                        TYPE="files" 
                        ;;
                c)      
                        TYPE="database"
                        TYPE2="files"
                        ;;
                h)
                        echo "Usage:"
                        echo "backup.sh -h "
                        echo "backup.sh -d "
                        echo "backup.sh -f "
                        echo ""
                        echo "   -d     to perform database backup"
                        echo "   -f     to perform files backup"
                        echo "   -c     to perform full backup"
                        echo "   -h     help (this output)"
                        exit 0
                        ;;

        esac
done

if [ $TYPE = "database" ]
then
    #Databases Backup...
    echo "Databases backup ..." 
    #Create remote database backup configuration file, and check if there is a folder for temporary backups
    ssh -p $SERVER_PORT $USER@$SERVER_HOST "echo -e '[mysqldump]\nuser=$DB_USER\npassword=$DB_PASSWORD\n\n[mysql]\nuser=$DB_USER\npassword=$DB_PASSWORD' > .my.cnf | if [[ -d $TEMP_FOLDER ]]; then rm -R $TEMP_FOLDER  ;fi | mkdir $TEMP_FOLDER"
    #create a mysqldump of every database in the server, put it in the temporary backup folder and gzip it
    ssh -p $SERVER_PORT $USER@$SERVER_HOST 'mysql -N -e "show databases" | while read dbname; do mysqldump --complete-insert --routines --triggers --single-transaction "$dbname" > '$TEMP_FOLDER'/$dbname$(date +"%d-%m-%Y").sql && gzip '$TEMP_FOLDER'/$dbname$(date +"%d-%m-%Y").sql; done'
    #Get database backup from server to local /backup folder
    mkdir -p $LOCAL_BACKUP/$SERVER_HOST/Databases
    scp -P $SERVER_PORT $USER@$SERVER_HOST:$TEMP_FOLDER/*.sql.gz $LOCAL_BACKUP/$SERVER_HOST/Databases/. 
    #clearup server side files
    ssh -p $SERVER_PORT $USER@$SERVER_HOST "rm -r $TEMP_FOLDER | rm .my.cnf"
    echo "done!";
    if [ $TYPE2 = "files" ] 
    then 
        $TYPE = $TYPE2; 
    fi
fi

if [ $TYPE = "files" ]
then
echo "Files backup..."
#create file backup to pull
ssh -p $SERVER_PORT $USER@$SERVER_HOST "mkdir -p $TEMP_FOLDER | tar -zcf $TEMP_FOLDER/directory_backup_$(date +"%d-%m-%Y").tar.gz $REMOTE_FILES_PATH" 
#pull the file to local backup folder
mkdir -p $LOCAL_BACKUP/$SERVER_HOST/Files
scp -P $SERVER_PORT $USER@$SERVER_HOST:$TEMP_FOLDER/*.tar.gz $LOCAL_BACKUP/$SERVER_HOST/Files/.
#clear remote server side  temp files
ssh -p $SERVER_PORT $USER@$SERVER_HOST "rm -R $TEMP_FOLDER";
fi

