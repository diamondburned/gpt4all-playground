package main

import (
	"bufio"
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"runtime"

	gpt4all "github.com/nomic-ai/gpt4all/gpt4all-bindings/golang"
)

var (
	model  = "ggml-model-gpt4all-falcon-q4_0.bin"
	tokens = 512
	topK   = 90
	topP   = 0.86
)

func init() {
	log.SetFlags(0)

	flag.StringVar(&model, "m", model, "model file")
	flag.IntVar(&tokens, "t", tokens, "tokens")
	flag.IntVar(&topK, "K", topK, "topK")
	flag.Float64Var(&topP, "P", topP, "topP")
}

func main() {
	flag.Parse()

	modelPath := filepath.Join(os.Getenv("GPT4ALL_MODELS"), model)
	log.Println("using model:", modelPath)

	// Load the model
	model, err := gpt4all.New(modelPath,
		gpt4all.SetThreads(runtime.GOMAXPROCS(0)),
		gpt4all.SetLibrarySearchPath(os.Getenv("LIBRARY_PATH")))
	if err != nil {
		log.Fatalln("model error:", err)
	}
	defer model.Free()

	model.SetTokenCallback(func(s string) bool {
		fmt.Print(s)
		return true
	})

	log.Println("model loaded")

	scanner := bufio.NewScanner(os.Stdin)
	scan := func() bool {
		fmt.Print("> ")
		return scanner.Scan()
	}

	for scan() {
		_, err = model.Predict(scanner.Text(),
			gpt4all.SetTokens(tokens),
			gpt4all.SetTopK(topK),
			gpt4all.SetTopP(topP))
		if err != nil {
			log.Fatalln("predict error:", err)
		}

		fmt.Println()
		fmt.Println()
	}
}
