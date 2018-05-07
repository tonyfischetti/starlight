#!/bin/bash

raco exe --gui --icns ./icon/sample.icns ++lib racket/lang/reader ++lib racket/gui ++lib framework Starlight.rkt
raco distribute mac-app Starlight.app
rm -rf Starlight.app
