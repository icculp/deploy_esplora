#!/usr/bin/env bash
filename=lightmode.tar.gz

# tar --delete --file=googlecl-0.9.7.tar googlecl-0.9.7/README.txt

for file in [[tar --gzip --list --verbose --file=$filename]] ; do 
	tar xzvf "${file}"rm "${file}"; done
