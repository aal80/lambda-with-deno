# lambda-with-deno (experiment)

In order to get things running yourself you'll need basic understanding of [working with makefiles](https://makefiletutorial.com/). 

See `makefile`.

## TOC
* [Components](#components)
* [Runtimes](#runtimes)
* [Performance testing](#performance-testing)

## Components

This project has three major components (from bottom to top) - Deno layer, Runtime layer, and Function code.

### Deno layer

Function logic is implemented using TypeScript, and runs in isolated environment provided by Deno runtime. Deno binary is ~90mb. In order not to bundle it as part of the the runtime, or even worse as part of the function, the deno binary is deployed as a separate layer. You will probably need to deploy this layer just once. The only reason to redeploy it is if you want to update Deno version. 

Use `make deploy_deno_layer` to deploy the Deno layer. Note the layer ARN, you'll need it to deploy the function.

### Runtime layer

Runtime layer provides custom Lambda runtime built on top of `provided.al2` runtime.

Runtime layer contains 
* `bootstrap` - a binary built from Golang sources that implements Lambda Runtime API client. Bootstrap is responsible for copying Deno cache files from the Runtime layer and Function to the writable `/tmp` folder, and starting a Deno server. See the [Runtimes](#runtimes) section below to understand how Runtime works. 
* `runtime.js` - this is the JavaScript part of the runtime. We want function code to be generic and fully decoupled from the runtime implementation specifics, this is what `runtime.js` is responsible for. It provides a bridge between the Golang code and Function code. 
* `function.bundle.js` - this is a dummy function bundle to be used mostly for debugging the runtime layer when a real function code is not available. When using the runtime layer as intended, the `function.bundle.js` from Function will overwrite the `function.bundle.js` from the runtime layer. 

Note that the `runtime.js` is intentionally implemented in JavaScript and not TypeScript in order to avoid having to transpile it. `runtime.js` is intended to remain only a slim bridging component, so it can be loaded very fast.

### Function

Function has only one file - `function.bundle.js`. It is transpiled from `/src/function` via `deno cache && deno bundle` (see makefile). We want this file to be loaded as fast as possible. 

## Runtimes

This project is intended to contain two runtime implementations - runtime1 and runtime2. They have similar file structure, and follow the same layered approach outlined above, but they differ in the way they use Deno. 

- Runtime1 is spawning one Deno process on function init. In that process it will run a simple http server implemented in `runtime.js` Each function invocation will trigger an http request to the runtime server with event data, the runtime server will invoke the handler in `function.bundle.js` with the event data, and return response back to the runtime layer via http response. This allows to spawn one Deno process per execution envrionment lifecycle and reuse it across multiple function invocations. 

![](/diagrams/runtime1.png)

- Runtime2 is taking a different approach. Instead of creating one Deno process reused across all invocations, it spawns a new Deno process for each invocation. Each function invocation will result in a new Deno process spawned running `runtime.js`, which will invoke the handler from `function.bundle.js` with event data. The response is printed to the stdout, parsed via the Golang code, and returned back to Lambda. 

> NOTE: Implementation TBD
