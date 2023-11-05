#!/bin/bash

unzip compiler_gnu_linux.zip -d compiler_gnu_linux &&\
mkdir _site &&\
mv compiler_gnu_linux/docs _site/docs &&\
rm -r compiler_gnu_linux
