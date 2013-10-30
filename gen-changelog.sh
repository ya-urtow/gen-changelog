#!/bin/bash
#Author: Biriyukov-Romanov <urtow@tandex-team.ru>

PROJECT="YOUR PROJECT NAME HERE"

CHANGELOG=debian/changelog
HASH=$(git log -n 1 --pretty=oneline debian/changelog | awk '{print $1}')
TMPFILE=/tmp/$HASH.tmp
CURVERSION=$(dpkg-parsechangelog | awk '/Version:/ {print $2}')
NEXTVERSION=$(echo $CURVERSION | tr "." " " | awk '{print $1 "." $2+1}')

HEAD="$PROJECT ($NEXTVERSION) stable; urgency=low"
BUILDERNAME=$(git config --get user.name)
BUILDEREMAIL=$(git config --get user.email)
CRURRENTDATE=$(LANG=en_EN date  +"%a, %d %b %Y %H:%M:%S %z")
BOTTOM="-- $BUILDERNAME <$BUILDEREMAIL>"

ISCHANGED=$(git log -n 1 --pretty=oneline $HASH..HEAD ./ | awk '{print $1}')

CURRENTBRANCH=$(git branch | grep ^* | awk '{ print $2 }')

if [ $CURRENTBRANCH != 'dev' ]; then
    echo "You are not in dev branch! Please checkout to dev branch. Command:
    git branch dev"
    exit 2;
fi

if [ -z $CURVERSION ]; then
    echo 'Can`t found last version in first line in changelog'
    exit 1
fi

echo $HEAD > $TMPFILE
echo >> $TMPFILE

if [ -z $ISCHANGED ]; then
    echo '  * bump version' >> $TMPFILE;
else
    git log --pretty=oneline $HASH..HEAD ./ | sed 's/^[A-Za-z0-9]* /  * /' >> $TMPFILE
fi

echo >> $TMPFILE
echo -n ' ' >> $TMPFILE
echo -n $BOTTOM >> $TMPFILE
echo -n '  ' >> $TMPFILE
echo $CRURRENTDATE >> $TMPFILE
echo >> $TMPFILE

mv $CHANGELOG /tmp/$HASH.old
mv $TMPFILE $CHANGELOG
cat /tmp/$HASH.old >> $CHANGELOG
rm /tmp/$HASH.old

git add $CHANGELOG
git commit -m "Update package version to $NEXTVERSION"
git checkout master
echo "Merge changes"
git merge dev
if [ $? -ne 0  ]; then
  echo "!!!SOMETHING GOING WRONG!!! Please check output of last command (git merge dev) it will help"
  exit 1
fi

echo "Push changes"
git push
if [ $? -ne 0  ]; then
  echo "!!!SOMETHING GOING WRONG!!! Please check output of last command (git push) it will help"
  exit 1
fi

echo "Return to dev branch"
git checkout dev
echo "Now you can run Jenkins job"
