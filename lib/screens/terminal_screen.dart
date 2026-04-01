import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final terminal = Terminal();
  SSHClient? _client;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    terminal.write('Connecting to k8s node...\r\n');
    try {
      final socket = await SSHSocket.connect('localhost', 2222);
      _client = SSHClient(
        socket,
        username: 'root',
        onPasswordRequest: () => 'alpine',
      );

      final session = await _client!.shell();

      terminal.onOutput = (data) {
        session.write(utf8.encode(data));
      };

      session.stdout.listen((data) {
        terminal.write(utf8.decode(data));
      });

      session.stderr.listen((data) {
        terminal.write(utf8.decode(data));
      });

    } catch (e) {
      terminal.write('Connection failed: $e\r\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('k8s Node Shell')),
      backgroundColor: Colors.black,
      body: TerminalView(terminal),
    );
  }

  @override
  void dispose() {
    _client?.close();
    super.dispose();
  }
}
