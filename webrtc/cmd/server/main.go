package main

import (
	"flag"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v3"
)

// Basic WebRTC signaling server
func main() {
	addr := flag.String("addr", ":8080", "http service address")
	flag.Parse()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		upgrader := websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		}
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			log.Printf("Upgrade error: %v", err)
			return
		}
		defer conn.Close()

		log.Println("New WebSocket connection established")
		log.Println("WebRTC is initialized successfully")

		// Keep connection open
		for {
			messageType, message, err := conn.ReadMessage()
			if err != nil {
				log.Println("Read error:", err)
				break
			}
			log.Printf("Received message: %s", message)
			
			// Echo the message back
			if err := conn.WriteMessage(messageType, message); err != nil {
				log.Println("Write error:", err)
				break
			}
		}
	})

	log.Printf("Starting WebRTC signaling server on %s", *addr)
	log.Fatal(http.ListenAndServe(*addr, nil))
}