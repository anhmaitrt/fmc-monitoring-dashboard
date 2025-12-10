import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platform Stats',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StatsPage(),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int androidCount = 0;
  int iosCount = 0;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/users.json');
      final List<dynamic> data = jsonDecode(jsonStr);

      int android = 0;
      int ios = 0;

      for (final row in data) {
        if (row is List && row.length > 3) {
          final platform = (row[3] ?? '').toString().toLowerCase();
          if (platform == 'android') android++;
          if (platform == 'ios') ios++;
        }
      }

      setState(() {
        androidCount = android;
        iosCount = ios;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Stats from JSON'),
      ),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : error != null
            ? Text('Error: $error')
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total users: ${androidCount + iosCount}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statCard('Android', androidCount, Colors.green),
                const SizedBox(width: 16),
                _statCard('iOS', iosCount, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
