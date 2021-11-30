import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:wifi_connector/wifi_connector.dart';
import 'package:http/http.dart' as http;

const String DEFAULT_SSID = 'id_fhkiel-';
const NetworkSecurity STA_DEFAULT_SECURITY = NetworkSecurity.WPA;
const String DEFAULT_PORT_ADDRESS = '192.168.4.1';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi-IoT',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'WiFi-IoT'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextStyle textStyle = const TextStyle(color: Colors.white);
  List<WifiNetwork?>? _htResultNetwork;
  bool _isConnectedToWiFi = false;
  bool _isConnectedToPlug = false;
  String _currentSSID = '';
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  late TextEditingController _aP1SSIdController;
  late TextEditingController _aP1PasswordController;
  late TextEditingController _aP2SSIdController;
  late TextEditingController _aP2PasswordController;
  late TextEditingController _hostnameController;
  late TextEditingController _CORSDomainController;

  @override
  initState() {
    _aP1SSIdController = TextEditingController();
    _aP1PasswordController = TextEditingController();
    _aP2SSIdController = TextEditingController();
    _aP2PasswordController = TextEditingController();
    _hostnameController = TextEditingController();
    _CORSDomainController = TextEditingController();

    _hostnameController.text = '%s-%04d';

    WiFiForIoTPlugin.isConnected().then((val) {
      _isConnectedToWiFi = val;
    });

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      print(result);
      if (result == ConnectivityResult.wifi) {
        _checkSSID();
      } else if (_isConnectedToPlug) {
        setState(() {
          _isConnectedToPlug = false;
        });
      }
    });

    super.initState();
  }

  Future<void> _checkSSID() async {
    bool _connectedToPlug = false;
    String? _ssid = await WiFiForIoTPlugin.getSSID();
    if (_ssid != null && _ssid.contains(DEFAULT_SSID)) {
      _connectedToPlug = true;
    }

    setState(() {
      _isConnectedToPlug = _connectedToPlug;
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> setCurrentSSID() async {
    _currentSSID = (await WiFiForIoTPlugin.getSSID())!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _isConnectedToPlug ? form() : scan(),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget scan() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        MaterialButton(
          color: Colors.blue,
          child: Text("Scan", style: textStyle),
          onPressed: () async {
            _htResultNetwork = await loadWifiList();
            setState(() {});
          },
        ),
        SizedBox(
          child: getFiWiPointsList(),
          height: 300,
        ),
      ],
    );
  }

  Widget form() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'AP1 SSId',
              filled: true,
              isDense: true,
            ),
            controller: _aP1SSIdController,
            autocorrect: false,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'AP1 Password',
              filled: true,
              isDense: true,
            ),
            controller: _aP1PasswordController,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'AP2 SSId',
              filled: true,
              isDense: true,
            ),
            controller: _aP2SSIdController,
            autocorrect: false,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'AP2 Password',
              filled: true,
              isDense: true,
            ),
            controller: _aP2PasswordController,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Hostname',
              filled: true,
              isDense: true,
            ),
            controller: _hostnameController,
            autocorrect: false,
          ),
          const SizedBox(
            height: 12,
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'CORS Domain',
              filled: true,
              isDense: true,
            ),
            controller: _CORSDomainController,
            autocorrect: false,
          ),
          const SizedBox(
            height: 24,
          ),
          RaisedButton(
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            child: const Text('Save'),
            onPressed: _savePlugSettings,
          ),
        ],
      ),
    );
  }

  Future<void> _savePlugSettings() async {
    final queryParameters = {
      'p1': _aP1PasswordController.text,
      's1': _aP1SSIdController.text,
      'p2': _aP2PasswordController.text,
      's2': _aP2SSIdController.text,
      'h': _hostnameController.text,
      'c': _CORSDomainController.text,
    };
    final uri = Uri.https(DEFAULT_PORT_ADDRESS, '/wi', queryParameters);
    final response = await http.get(uri);
  }

  Future<List<WifiNetwork>> loadWifiList() async {
    List<WifiNetwork> htResultNetwork;
    try {
      htResultNetwork = await WiFiForIoTPlugin.loadWifiList();
    } on PlatformException {
      htResultNetwork = <WifiNetwork>[];
    }

    return htResultNetwork;
  }

  Widget getFiWiPointsList() {
    List<ListTile> htNetworks = <ListTile>[];

    if (_htResultNetwork != null) {
      _htResultNetwork!.forEach((oNetwork) {
        htNetworks.add(ListTile(
          title: Text(oNetwork!.ssid ?? 'null'),
          trailing: MaterialButton(
            color: Colors.blue,
            child: Text("Connect", style: textStyle),
            onPressed: () {
              print('connect to ' + (oNetwork.ssid ?? ''));

              WiFiForIoTPlugin.connect(oNetwork.ssid ?? '', joinOnce: true, security: NetworkSecurity.NONE).then((value) => print('WiFiForIoTPlugin.connect = ' + value.toString()));

              //final isSucceed = WifiConnector.connectToWifi(ssid: oNetwork.ssid ?? '', password: 'kornnick').then((value) => print('WifiConnector = ' + value.toString()));
            },
          ),
        ));
      });
    }

    return ListView(
      padding: kMaterialListPadding,
      children: htNetworks,
    );
  }
}
