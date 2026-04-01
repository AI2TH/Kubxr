import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VmState()),
      ],
      child: const K8sNodeApp(),
    ),
  );
}

class VmState extends ChangeNotifier {
  String _status = 'stopped';
  String get status => _status;

  void setStatus(String status) {
    _status = status;
    notifyListeners();
  }
}

class K8sNodeApp extends StatelessWidget {
  const K8sNodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'k8s Node',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vmState = context.watch<VmState>();

    return Scaffold(
      appBar: AppBar(title: const Text('k8s Node Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainValueAlignment.center,
          children: [
            const Icon(Icons.hub, size: 100, color: Colors.teal),
            const SizedBox(height: 20),
            Text(
              'Status: ${vmState.status.toUpperCase()}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                vmState.setStatus(vmState.status == 'stopped' ? 'running' : 'stopped');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              child: Text(vmState.status == 'stopped' ? 'START VM' : 'STOP VM'),
            ),
          ],
        ),
      ),
    );
  }
}
