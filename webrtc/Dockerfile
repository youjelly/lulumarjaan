FROM usamazaidi/webrtc-base:latest

WORKDIR /app

# Copy source code
COPY . .

# Use the module from the base image and add any missing dependencies
RUN go mod tidy
RUN go get github.com/gorilla/websocket
RUN go get github.com/pion/webrtc/v3

# Build the application
RUN go build -o webrtc-server ./cmd/server

# Expose port
EXPOSE 8080

# Run the application
CMD ["./webrtc-server"]