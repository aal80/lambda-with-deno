import { handler } from './function.bundle.js'

import { serve } from "https://deno.land/std@0.147.0/http/server.ts";

const port = 8080;

const requestHandler = async (request)=> {
  console.log(`runtime.js:requestHandler ${request.method}`);
  if (request.method==='GET'){
    return new Response('OK', { status: 200 });
  }

  const requestBody = await request.json();
  console.log('runtime.js:requestBody:', requestBody);

  const handlerResponse = await handler(requestBody);
  console.log('runtime.js:handlerResponse:', handlerResponse);

  return new Response(JSON.stringify(handlerResponse), { status: 200 });
};


console.log(`runtime.js:HTTP webserver running`);
await serve(requestHandler, { port });

