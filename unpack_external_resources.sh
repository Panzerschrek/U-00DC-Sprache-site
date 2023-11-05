#!/bin/bash

# Deal with the interpreter
mv "Interpreter build/Interpreter.js" "Interpreter.js" &&\
mv "Interpreter build/Interpreter.wasm" "Interpreter.wasm" &&\
mv "Interpreter build/Interpreter_launcher.js" "Interpreter_launcher.js" &&\
rm -r "Interpreter build" &&\
\
# Unpack the docs
unzip compiler_gnu_linux.zip -d compiler_gnu_linux &&\
mv compiler_gnu_linux/docs docs &&\
rm -r compiler_gnu_linux &&\
\
# Hack for docs - Jekyll ignores files/directories with "_" prefix. But docs built by Sphinx may contain such directories. So, disable inspection of the docs directory by Jekyll by creating special marker file.
touch docs/.nojekyll
