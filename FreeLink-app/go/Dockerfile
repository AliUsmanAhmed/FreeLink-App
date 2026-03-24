# build stage
FROM golang:1.21-alpine AS builder
WORKDIR /src
RUN apk add --no-cache git ca-certificates
COPY go.mod go.sum ./
RUN go mod download
COPY . .
WORKDIR /src/server
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /freelink-server

# runtime stage
FROM alpine:3.18
RUN apk add --no-cache ca-certificates
COPY --from=builder /freelink-server /usr/local/bin/freelink-server
EXPOSE 4000
ENTRYPOINT ["/usr/local/bin/freelink-server"]