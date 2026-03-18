// go/main.go
package main

/*
#include <jni.h>
#include <stdbool.h>
*/
import "C"
import (
  "encoding/binary"  // ← ADD THIS LINE
  "crypto/rand"
  "errors"
  "fmt"
  "io"
  "log"
  "net"
  "runtime"
  "sync"
  "time"

  "golang.org/x/crypto/nacl/box"
  "golang.org/x/crypto/curve25519"
)

var (
	tunnelRunning bool
	mutex         sync.Mutex
	stopCh        = make(chan bool, 1)
)

//export StartFreeLinkTunnel
func StartFreeLinkTunnel(host *C.char, port C.int, pubkeyHex *C.char) C.bool {
	mutex.Lock()
	defer mutex.Unlock()

	if tunnelRunning {
		return C.bool(true)
	}

	hostStr := C.GoString(host)
	pubkeyStr := C.GoString(pubkeyHex)
	portInt := int(port)

	pubkey, err := hex.DecodeString(pubkeyStr)
	if err != nil || len(pubkey) != 32 {
		log.Printf("Invalid public key")
		return C.bool(false)
	}

	tunnelRunning = true

	go func() {
		err := runTunnel(hostStr, portInt, pubkey)
		if err != nil {
			log.Printf("Tunnel failed: %v", err)
		}
		mutex.Lock()
		tunnelRunning = false
		mutex.Unlock()
	}()

	runtime.Gosched()
	return C.bool(true)
}

//export StopFreeLinkTunnel
func StopFreeLinkTunnel() C.bool {
	mutex.Lock()
	if !tunnelRunning {
		mutex.Unlock()
		return C.bool(false)
	}
	stopCh <- true
	tunnelRunning = false
	mutex.Unlock()
	return C.bool(true)
}

func runTunnel(serverHost string, serverPort int, serverPubKey []byte) error {
	addr := fmt.Sprintf("%s:%d", serverHost, serverPort)

	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return err
	}
	defer conn.Close()

	// STEP 1: Obfuscation Handshake (Curve25519)
	var clientPriv [32]byte
	if _, err := rand.Read(clientPriv[:]); err != nil {
		return err
	}
	var clientPub [32]byte
	curve25519.ScalarBaseMult(&clientPub, &clientPriv)

	// Send: 2-byte length + 32-byte public
	binary.Write(conn, binary.BigEndian, uint16(32))
	conn.Write(clientPub[:])

	// Read: 2-byte length + 32-byte server public
	var length uint16
	binary.Read(conn, binary.BigEndian, &length)
	if length != 32 {
		return errors.New("server: invalid pub len")
	}
	var serverEphPub [32]byte
	io.ReadFull(conn, serverEphPub[:])

	// Compute shared secret: S = serverEphPub ^ clientPriv
	var shared [32]byte
	curve25519.ScalarMult(&shared, &clientPriv, &serverEphPub)

	// STEP 2: Use shared key for NaCl box (ChaCha20-Poly1305)
	var clientPubBox, serverPubBox [32]byte
	copy(clientPubBox[:], clientPub[:32])
	copy(serverPubBox[:], serverPubKey[:32])

	// Client sends encrypted: own public key
	encPub := box.Seal(nil, clientPub[:], &zeroNonce, &serverPubBox, shared[:])

	// Write length + encrypted
	binary.Write(conn, binary.BigEndian, uint16(len(encPub)))
	conn.Write(encPub)

	// Read server's encrypted public
	var encLen uint16
	binary.Read(conn, binary.BigEndian, &encLen)
	encServerPub := make([]byte, encLen)
	io.ReadFull(conn, encServerPub)

	_, ok := box.Open(nil, encServerPub, &zeroNonce, &clientPubBox, shared[:])
	if !ok {
		return errors.New("decrypt failed")
	}

	// ✅ Noise IK-like handshake complete
	// Now act as SOCKS5 local proxy
	go startLocalProxy(conn)

	// Wait or stop
	select {
	case <-stopCh:
		return nil
	}
}

var zeroNonce [24]byte

func startLocalProxy(remoteConn net.Conn) {
	// Start local SOCKS5 on 127.0.0.1:1080
	// This is simplified — full version would parse SOCKS5
	// But for now: just pipe data
	log.Println("SOCKS5 proxy started on :1080")

	// You can expand this later
	listener, err := net.Listen("tcp", "127.0.0.1:1080")
	if err != nil {
		log.Printf("SOCKS5 failed: %v", err)
		return
	}
	defer listener.Close()

	for {
		clientConn, err := listener.Accept()
		if err != nil {
			return
		}
		go pipe(clientConn, remoteConn)
	}
}

func pipe(client net.Conn, server net.Conn) {
	defer client.Close()
	defer server.Close()

	go io.Copy(server, client)
	io.Copy(client, server)
}

func main() {} // Required
