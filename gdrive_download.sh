#!/usr/bin/env bash
# put googleID of filename here
# when you share the file, take the id from:
# https://drive.google.com/file/d/1O4jtsCP36RdEOkLxn1f1MY0hqa1F6DLy/view?usp=sharing
# ggID=1O4jtsCP36RdEOkLxn1f1MY0hqa1F6DLy
ggID='1O4jtsCP36RdEOkLxn1f1MY0hqa1F6DLy'  
ggURL='https://drive.google.com/uc?export=download'  
filename="$(curl -sc /tmp/gcokie "${ggURL}&id=${ggID}" | grep -o '="uc-name.*</span>' | sed 's/.*">//;s/<.a> .*//')"  
getcode="$(awk '/_warning_/ {print $NF}' /tmp/gcokie)"  
curl -Lb /tmp/gcokie "${ggURL}&confirm=${getcode}&id=${ggID}" -o lightmode.tar.gz
# add below if you want to specify filename
# -o "${filename}"  




