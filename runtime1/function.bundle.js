async function handler (event){
    console.log('> dummy handler');
    console.log({event});
    console.log('< dummy handler');
    if (event.action==='kill'){
        Deno.exit();
    }
    return {
        message:"hello from a dummy handler"
    }
}

export {handler}