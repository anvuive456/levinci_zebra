import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:levinci_zebra/levinci_zebra.dart';
import 'package:levinci_zebra/models/printer.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    runApp(const MyApp());
  }, (error, stack) {
    print(error);
    print(stack);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  String _platformVersion = 'Unknown';
  final _levinciZebraPlugin = LevinciZebra();
  List<DiscoveredPrinter> _devices = [];
  DiscoveredPrinter? _selectedPrinter;
  final TextEditingController _commandController =
      TextEditingController(text: '^XA^FO50,50^ADN,36,20^FDHello Zebra!^FS^XZ');

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _levinciZebraPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> discoverByLan() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Discovering printers by LAN...'),
      ),
    );
    print('[DEBUG] Flutter: discoverByLan button pressed');
    final devices = await _levinciZebraPlugin.discoverByLan();
    print('[DEBUG] Flutter: discoverByLan result: ' + devices.toString());
    setState(() {
      _devices = devices ?? [];
      _selectedPrinter = null;
    });
  }

  Future<void> discoverByBroadcast() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Discovering printers by broadcast...'),
      ),
    );
    print('[DEBUG] Flutter: discoverByBroadcast button pressed');
    final devices = await _levinciZebraPlugin.discoverByBroadcast();
    print('[DEBUG] Flutter: discoverByBroadcast result: ' + devices.toString());
    setState(() {
      _devices = devices ?? [];
      _selectedPrinter = null;
    });
  }

  Future<void> discoverByHops(int hops) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Discovering printers by hops = $hops...'),
      ),
    );
    print('[DEBUG] Flutter: discoverByHops button pressed, hops = ' +
        hops.toString());
    final devices = await _levinciZebraPlugin.discoverByHops(hops: hops);
    print('[DEBUG] Flutter: discoverByHops result: ' + devices.toString());
    setState(() {
      _devices = devices ?? [];
      _selectedPrinter = null;
    });
  }

  Future<void> sendPrintCommand() async {
    if (_selectedPrinter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a printer!')),
      );
      return;
    }
    final ip = _selectedPrinter!.address;
    final port = _selectedPrinter!.port ?? 9100;
    final command = _commandController.text;
    try {
      await _levinciZebraPlugin.sendCommand(
        ipAddress: ip,
        port: port,
        command: command,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print command sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send print command: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Running on: $_platformVersion\n'),
          ElevatedButton(
              onPressed: discoverByLan,
              child: Text('Discover Printers By LAN')),
          ElevatedButton(
              onPressed: discoverByBroadcast,
              child: Text('Discover Printers By Broadcast')),
          ElevatedButton(
              onPressed: () => discoverByHops(2),
              child: Text('Discover Printers By Hops = 2')),
          const SizedBox(height: 16),
          Text('Devices:'),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final printer = _devices[index];
                final selected = printer == _selectedPrinter;
                return ListTile(
                  title: Text(printer.toString()),
                  selected: selected,
                  onTap: () {
                    setState(() {
                      _selectedPrinter = printer;
                    });
                  },
                  trailing: selected
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commandController,
            onTapOutside: (event) {
              FocusScope.of(context).unfocus();
            },
            decoration: InputDecoration(
              labelText: 'Print Command (ZPL)',
              border: OutlineInputBorder(),
            ),
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
//               _commandController.text = '''
// ^XA
// ^FO100,100
// ^BUN,100,Y,N
// ^FD012345678905^FS
// ^XZ
// ''';
              _commandController.text = '''
^XA
^BY2,3,10
^FO50,50,2
^BUN,50,Y,N,Y
^FD01234567890^FS
^XZ
  ''';
            },
            child: Text('Dán lệnh in mã UPC-A mẫu'),
          ),
          ElevatedButton(
            onPressed: sendPrintCommand,
            child: Text('Send Print Command'),
          ),
          SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
