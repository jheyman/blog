#! /bin/bash

SUSPICIOUS="##"

find _site/ -name "*.htm*" | xargs grep $SUSPICIOUS &> tmp.log
if [ $? == 0 ]
then
   echo "*************************************"
   echo "KO, found suspicious characters: $SUSPICIOUS" 
   echo "in the generated HTML pages:"
   echo "*************************************"
   more tmp.log
else
   echo "Check for suspicious characters in generated HMTL: OK"
fi

