import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// --- FFI Declaration (Stubs until AAR is built) ---
typedef StartFreeLinkTunnel = bool Function(String host, int port, String pubkey);
typedef StopFreeLinkTunnel = bool Function();

// Replace with actual from AAR when built
bool StartFreeLinkTunnel(String host, int port, String pubkey) {
  print("🟡 DUMMY: StartFreeLinkTunnel($host:$port, $pubkey)");
  return true;
}

bool StopFreeLinkTunnel() {
  print("🟡 DUMMY: StopFreeLinkTunnel()");
  return true;
}

// --- App ---
void main() => runApp(FreeLinkApp());

class FreeLinkApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreeLink',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isConnected = false;

  void _toggleConnection() async {
    setState(() {
      _isConnected = !_isConnected;
    });

    if (_isConnected) {
      bool success = StartFreeLinkTunnel(
        'your-node.freelink.net', // Replace with real
        8484,
        'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4', // 32-byte hex
      );
      if (!success) {
        setState(() {
          _isConnected = false;
        });
      }
    } else {
      StopFreeLinkTunnel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FreeLink')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shield,
              size: 80,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _isConnected ? 'PROTECTED' : 'NOT CONNECTED',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isConnected ? Colors.red : Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
              ),
              child: Text(
                _isConnected ? 'DISCONNECT' : 'CONNECT',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
