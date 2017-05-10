#!/bin/bash
dirlist=(
 extjs/packages/amf/src
 extjs/packages/core/src
 extjs/packages/core/overrides
 extjs/packages/charts/src/
 extjs/packages/charts/overrides
 extjs/packages/charts/classic/src
 extjs/packages/charts/classic/overrides
 extjs/packages/google/src
 extjs/packages/google/classic/src
 extjs/packages/soap/src
 extjs/packages/ux/src
 extjs/packages/ux/classic/src
 extjs/classic/classic/src
 extjs/classic/classic/overrides
)

bin/jsduck --warnings=-global --template template-extjs411 --extjs-path extjs/ext-all-debug-w-comments.js --output output/e621_classic "${dirlist[@]}"
