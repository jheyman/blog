#! /bin/bash

jekyll build
cd publish/blog/
rsync -arv ../../_site/ .
git add . --all
git commit -m "$1"
git push -u origin gh-pages
