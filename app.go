package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	log.Print("Request received")
	fmt.Fprintf(w, "<h1>Hello %s, this is a local change!</h1>", os.Getenv("HELLO_MSG"))
}

func main() {
	log.Print("Server started")
	http.HandleFunc("/", handler)
	http.ListenAndServe(":80", nil)
}
