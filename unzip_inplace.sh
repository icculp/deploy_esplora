#!/usr/bin/env bash
'''
If you don't have enough space left on the drive to hold the compressed and decompressed archives, you can decompress it 'in-place' by extracing a single file at a time and subsequently deleting it, but this requires updating the entire archive (rewriting it to disk) every time which can be very time consuming. 
'''

filename=lightmode.tar.gz

# tar --delete --file=googlecl-0.9.7.tar googlecl-0.9.7/README.txt

for file in [[tar --gzip --list --verbose --file=$filename]] ; do 
	tar xzvf "${file}"rm "${file}"; done
