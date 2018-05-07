#!/bin/bash

raco exe --gui ++lib racket/lang/reader ++lib racket/gui ++lib framework starlight.rkt
raco distribute mac-app starlight.app
# rm -rf starlight.app
