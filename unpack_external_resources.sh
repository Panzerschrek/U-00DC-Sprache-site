#!/bin/bash

mv "Interpreter build/Interpreter.js" "Interpreter.js" &&\
mv "Interpreter build/Interpreter.wasm" "Interpreter.wasm" &&\
mv "Interpreter build/Interpreter_launcher.js" "Interpreter_launcher.js" &&\
rm -r "Interpreter build" &&\
mv "VisualStudioExtension/Ü_extension.vsix" "Ü_extension.vsix" &&\
rm -r "VisualStudioExtension"
