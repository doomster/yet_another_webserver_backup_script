# Yet another webserver backup script

It will get a copy of all databases and/or files from an assigned server. just add it to the crontab and setup the variables , and it will do the job

### Requirements:
- it will need passwordless ssh access to the remote server 
- you should know mysql credentials
- you should have access to read the files you want to backup


### How to use
Just run ./backup.sh followed by one of the flags :

   -d     to perform database backup
   
   -f     to perform files backup
   
   -c     to perform full backup
   
   -h     help (this output)
