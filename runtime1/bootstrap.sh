#!/bin/bash

set -x

mkdir -p /tmp/.deno_dir

# Copy from the runtime layer
cp -r /opt/.deno_dir/gen/. /tmp/.deno_dir/gen
cp -r /opt/.deno_dir/deps/. /tmp/.deno_dir/deps
cp /opt/runtime.js /tmp/runtime.js
cp /opt/function.bundle.js /tmp/function.bundle.js

# Copy from the function package
cp -r .deno_dir/gen/. /tmp/.deno_dir/gen
cp -r .deno_dir/deps/. /tmp/.deno_dir/deps
cp -r function.bundle.js /tmp/function.bundle.js

ls -la /tmp

echo All done! 