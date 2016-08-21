#! /bin/bash

# build site, commit and push generated files to github blog page

jekyll build
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
