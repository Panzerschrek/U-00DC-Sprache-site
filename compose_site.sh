#!/bin/bash

# Copy generated files into result directory.
# Doing so we bypass access rights issues of original generated directory (it seems to be read-only).
cp -r _site_generated _site &&\
\
# Extract docs into result directory.
unzip compiler_gnu_linux.zip -d compiler_gnu_linux &&\
mv compiler_gnu_linux/docs _site/docs &&\
rm -r compiler_gnu_linux
