#! /bin/bash

# generate site

jekyll build

# Check for generation errors that might have left MarkDown title characters un-processed

SUSPICIOUS="##"

find _site/ -name "*.htm*" | xargs grep $SUSPICIOUS &> tmp.log
if [ $? == 0 ]
then
   echo "*************************************"
   echo "KO, found suspicious characters: $SUSPICIOUS" 
   echo "in the generated HTML pages:"
   echo "*************************************"
   more tmp.log
   exit
else
   echo "Check for suspicious characters in generated HMTL: OK"
fi

# commit and push generated files to github blog page

cd publish/blog/
rsync -arv ../../_site/ .
git add . --all
git commit -m "$1"
git push -u origin gh-pages

# Now commit & push source files themselves
cd ../..
git add . --all
git commit -m "$1"
git push -u origin master
