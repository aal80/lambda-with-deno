// deno-lint-ignore-file

async function handler (event: any){
    console.log('> handler');
    let resp1 = await fetch('https://example.com');
    let resp2 = await fetch('https://amazon.com');
    let resp3 = await fetch('https://aws.amazon.com');

    return 'hello from function handler';
}

export {handler}
