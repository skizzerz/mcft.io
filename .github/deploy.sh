#!/bin/bash

# this script is executed on the webserver

# there's a bunch of sleep commands to guard things that don't necessarily
# complete in realtime; should evaluate if they're actually necessary
# and if they are how small we can make them

##########
# set up correct version of python/pip
##########
echo "Initializing deployment"
source /home/minecraft/nodevenv/app/16/bin/activate

SOURCEPATH=/home/minecraft/repositories/mcft.io
DESTPATH=/home/minecraft/app
BAKPATH=/home/minecraft/app.bak

##########
# make a backup
##########
echo "Creating backup"
rm -rf $BAKPATH
mv $DESTPATH $BAKPATH

##########
# copy files
##########
echo "Copying files"
mkdir $DESTPATH
mkdir $DESTPATH/tmp
cd $SOURCEPATH
cp -r . $DESTPATH

##########
# ensure dependencies are up to date
##########
echo "Ensuring updated dependencies"
cd $DESTPATH
npm install

##########
# cleanup unnecessary files
##########
rm -rf $DESTPATH/.git
rm -rf $DESTPATH/.github
rm -f $DESTPATH/.gitignore
rm -f $DESTPATH/.cpanel.yml

##########
# restart app
##########
echo "Restarting webapp"
touch $DESTPATH/tmp/restart.txt
sleep 5

##########
# test if app runs successfully
##########
SUCCESS=0
curl -f https://mcft.io > /dev/null
if [ $? -ne 0 ]; then
    SUCCESS=1
fi

sleep 5
if [ -s $DESTPATH/stderr.log ]; then
    SUCCESS=1
fi

##########
# restore backup if app didn't run successfully
##########
if [ $SUCCESS -eq 1 ]; then
    echo "Webapp failed, restoring backup. Below is what was found in the log:"
    cat $DESTPATH/stderr.log
    rm -rf $DESTPATH
    mv $BAKPATH $DESTPATH
    touch $DESTPATH/tmp/restart.txt
    sleep 5
    curl -f https://mcft.io > /dev/null
    echo "Backup restored"
fi

echo "Deployment complete"
exit $SUCCESS
