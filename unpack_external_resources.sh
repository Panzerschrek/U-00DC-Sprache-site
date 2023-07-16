#!/bin/bash

mv build/Interpreter.js Interpreter.js &&\
mv build/Interpreter.wasm Interpreter.wasm &&\
mv build/Interpreter_launcher.js Interpreter_launcher.js &&\
rm -r build
