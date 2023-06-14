#!/usr/bin/env bash

# sha256sum * | sed -e '/z.SHA256$/d' > z.SHA256

echo ""
compgen -G "*.asc"    > /dev/null 2>&1 && echo " :: gpg *.asc"          && gpg --verify ./*.asc
echo ""
compgen -G "*.sig"    > /dev/null 2>&1 && echo " :: gpg *.sig"          && gpg --verify ./*.sig
echo ""
compgen -G "*.b2sums" > /dev/null 2>&1 && echo " :: b2sum *.b2sums"     && b2sum     --ignore-missing -c ./*.b2sums
echo ""
compgen -G "*.sha256" > /dev/null 2>&1 && echo " :: sha256sum *.sha256" && sha256sum --ignore-missing -c ./*.sha256
echo ""
compgen -G "*.sha512" > /dev/null 2>&1 && echo " :: sha512sum *.sha512" && sha512sum --ignore-missing -c ./*.sha512

echo ""
compgen -G "*.SHA256" > /dev/null 2>&1 && echo " :: sha256sum *.SHA256" && sha256sum --ignore-missing -c ./*.SHA256
