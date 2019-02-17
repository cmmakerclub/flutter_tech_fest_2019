import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter/services.dart';

final MqttClient client =
    MqttClient('mqtt.cmmc.io', ''); //replace with your own mqtt

const String pubTopic = ''; //replace with your own mqtt topic

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CMMC Flutter MQTT Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'CMMC Flutter MQTT Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _state = "";

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  void initState() {
    onMqttConnect();
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<dynamic> onMqttConnect() async {
    client.logging(on: false);

    client.onDisconnected = onDisconnected;

    client.onConnected = onConnected;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier('') //replace with your own mqtt
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    print('CMMC::client connecting....');
    client.connectionMessage = connMess;

    try {
      await client.connect();
    } on Exception catch (e) {
      print('CMMC::client exception - $e');
      client.disconnect();
    }

    if (client.connectionStatus.state == MqttConnectionState.connected) {
      print('CMMC::client connected');
    } else {
      print(
          'CMMC::ERROR client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      exit(-1);
    }
    return 0;
  }

  Future<Null> _onPublishMessage(command) async {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(command);

    print('CMMC::Publishing our topic');
    client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload);

    print('CMMC::Sleeping....');
    await MqttUtilities.asyncSleep(120);
  }

  void onDisconnected() {
    print('CMMC::OnDisconnected client callback - Client disconnection');
    if (client.connectionStatus.returnCode == MqttConnectReturnCode.solicited) {
      print('CMMC::OnDisconnected callback is solicited, this is correct');
    }
    exit(-1);
  }

  void onConnected() {
    print(
        'CMMC::OnConnected client callback - Client connection was sucessful');
  }

  void _turnOn() {
    setState(() {
      _onPublishMessage("ON");
      _state = "ON";
    });
  }

  void _turnOff() {
    setState(() {
      _onPublishMessage("OFF");
      _state = "OFF";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'LED Status: ',
              ),
              Text(
                '$_state',
                style: Theme.of(context).textTheme.display1,
              ),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actionButtonGroup(),
        ));
  }

  List<Widget> actionButtonGroup() {
    return <Widget>[
      FloatingActionButton(
        onPressed: () {
          _turnOn();
        },
        heroTag: 'on',
        tooltip: 'ON',
        child: const Icon(Icons.blur_on),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: FloatingActionButton(
            onPressed: () {
              _turnOff();
            },
            heroTag: 'off',
            tooltip: 'OFF',
            child: const Icon(Icons.blur_off)),
      )
    ];
  }
}
