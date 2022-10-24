package main

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
)

type GenericDictionary map[string]interface{}

var l log.Logger

func Handler(ctx context.Context, event GenericDictionary) (GenericDictionary, error) {
	l.Println("> Handler")
	l.Println("incoming event:", event)

	eventJsonBytes, _ := json.Marshal(event)

	res, err := http.Post("http://localhost:8080", "application/json", bytes.NewBuffer(eventJsonBytes))

	if err != nil {
		l.Fatalln("Error invoking Deno server:", err.Error())
		return nil, nil
	}

	defer res.Body.Close()

	body, _ := io.ReadAll(res.Body)
	l.Println("Response body:", string(body))

	var result GenericDictionary
	json.Unmarshal(body, &result)

	return result, nil
}

func RunCmd(cmd *exec.Cmd) {
	l.Println("> RunCmd", cmd.Args)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Run()
	l.Println("< RunCmd")
}

func startDenoServer() {
	l.Println("> startDenoServer")
	RunCmd(exec.Command("/bin/sh", "/opt/bootstrap.sh"))

	// Start server
	cmd := exec.Command(
		"deno",
		"run",
		"--no-check",
		"--allow-net",
		"/tmp/runtime.js")
	// "runtime.js")

	cmd.Env = append(cmd.Env, "DENO_DIR=/tmp/.deno_dir")

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err := cmd.Start()
	if err != nil {
		l.Fatalln("startDenoServer:Deno server failed to start", err.Error())
		return
	}

	l.Println("startDenoServer:Waiting for Deno server to start up")
	// Let's do 100 attempts at 20ms interval
	attemptCounter := 0
	for attemptCounter < 100 {
		isDenoServerUp := checkDenoServerUp()
		if isDenoServerUp {
			l.Println("startDenoServer:Deno server is running, attempts:", attemptCounter)
			return
		} else {
			attemptCounter++
			time.Sleep(20 * time.Millisecond)
		}
	}

	l.Fatalln("startDenoServer:Deno server failed to start")
}

func checkDenoServerUp() bool {
	// l.Println("checkDenoServerUp")
	resp, err := http.Get("http://localhost:8080")
	if err != nil || resp.StatusCode != 200 {
		// l.Fatalln("Err:" + fmt.Sprint(err))
		return false
	} else {
		return true
	}
}

func main() {
	l = *log.New(os.Stdout, "", log.Lshortfile)
	l.Println("> main:starting Deno Server")
	startDenoServer()

	l.Println("> main:starting Lambda")
	lambda.Start(Handler)
}
