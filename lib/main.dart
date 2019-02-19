import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter/services.dart';

final MqttClient client = MqttClient(
    'mqtt.cmmc.io', 'clientId-DMzA9ut6aq'); //replace with your own mqtt

//replace with your own mqtt topic

class Result {
  final DeviceInfo deviceInfo;
  final List<SensorData> records;

  Result({this.deviceInfo, this.records});

  factory Result.fromJson(Map<String, dynamic> parsedJson) {
    var list = parsedJson['d'] as List;
    List<SensorData> recordsList =
        list.map((i) => SensorData.fromJson(i)).toList();

    return Result(records: recordsList);
  }
}

class DeviceInfo {
  final String ssid;
  final String chipId;
  final int flashSize;
  final String mac;
  final String id;
  final String clientId;
  final String deviceId;
  final String prefix;
  final String ip;
  final String version;

  DeviceInfo(
      {this.ssid,
      this.chipId,
      this.flashSize,
      this.mac,
      this.id,
      this.clientId,
      this.deviceId,
      this.prefix,
      this.ip,
      this.version});

  factory DeviceInfo.fromJson(Map<String, dynamic> parsedJson) {
    return DeviceInfo(
        ssid: parsedJson['info']['ssid'],
        chipId: parsedJson['info']['chipId'],
        flashSize: parsedJson['info']['flsahSize'],
        mac: parsedJson['info']['mac'],
        id: parsedJson['info']['id'],
        clientId: parsedJson['info']['client_id'],
        deviceId: parsedJson['info']['device_id'],
        prefix: parsedJson['info']['prefix'],
        ip: parsedJson['info']['ip'],
        version: parsedJson['info']['version']);
  }
}

class SensorData {
  final String myName;
  final int millis;
  final int relayState;
  final double temp2;
  final double temp3;
  final double temp4;
  final int updateInterval;
  final int heap;
  final int rssi;
  final int counter;
  final int subscription;

  SensorData(
      {this.myName,
      this.millis,
      this.relayState,
      this.temp2,
      this.temp3,
      this.temp4,
      this.updateInterval,
      this.heap,
      this.rssi,
      this.counter,
      this.subscription});

  factory SensorData.fromJson(Map<String, dynamic> parsedJson) {
    return SensorData(
        myName: parsedJson['myName'],
        millis: parsedJson['millis'],
        relayState: parsedJson['relayState'],
        temp2: parsedJson['temp2'],
        temp3: parsedJson['temp3'],
        temp4: parsedJson['temp4'],
        updateInterval: parsedJson['updateInterval'],
        heap: parsedJson['heap'],
        rssi: parsedJson['rssi'],
        counter: parsedJson['counter'],
        subscription: parsedJson['subscription']);
  }
}

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
        .withClientIdentifier(
            'clientId-DMzA9ut6aq') //replace with your own mqtt
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
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

  Future<Null> _onPublishMessage(pubTopic, command) async {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(command);

    print('CMMC::Publishing our topic');
    client.publishMessage(pubTopic, MqttQos.atMostOnce, builder.payload);

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

  Future<Result> _onSubscribeMessage(pubTopic) async {
    print('CMMC::Subscribing to the $pubTopic topic');
    final message = client.subscribe(pubTopic, MqttQos.exactlyOnce);
    return Result.fromJson(json.decode(message.changes.toString()));
  }

  void onConnected() {
    print(
        'CMMC::OnConnected client callback - Client connection was sucessful');
  }

  void _turnOn() {
    setState(() {
      _onPublishMessage("TECH_FEST/PLUG_005/\$/command", "ON");
      _state = "ON";
      _onSubscribeMessage("TECH_FEST/Grill/status");
    });
  }

  void _turnOff() {
    setState(() {
      _onPublishMessage("TECH_FEST/PLUG_005/\$/command", "OFF");
      _state = "OFF";
      _onSubscribeMessage("TECH_FEST/Grill/status");
    });
  }

  @override
  Widget build(BuildContext context) {
    // final key = GlobalKey<ScaffoldState>();
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: FutureBuilder<Result>(
            future: _onSubscribeMessage("TECH_FEST/Grill/status"),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: snapshot.data.records.length,
                    itemBuilder: (context, index) {
                      // Widget _buildImage() {
                      //   if (snapshot.data.residents[index].imageLink.isEmpty) {
                      //     return Container(
                      //       child: Image.asset(
                      //         'images/google_io_2018.jpg',
                      //         fit: BoxFit.fitWidth,
                      //       ),
                      //     );
                      //   } else {
                      //     return Image.network(
                      //         snapshot.data.residents[index].imageLink,
                      //         fit: BoxFit.fitWidth);
                      //   }
                      // }

                      return GestureDetector(
                          //You need to make my child interactive
                          // onTap: () {
                          //   Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => DetailScreen(
                          //             todo: snapshot.data.residents[index])),
                          //   );
                          // },
                          // onLongPress: () {
                          //   showDialog(
                          //       context: context,
                          //       builder: (BuildContext context) {
                          //         return SimpleDialog(
                          //           title: const Text('Would You like to do?'),
                          //           children: <Widget>[
                          //             SimpleDialogOption(
                          //               onPressed: () {
                          //                 Navigator.of(context,
                          //                         rootNavigator: true)
                          //                     .pop('dialog');
                          //                 key.currentState
                          //                     .showSnackBar(SnackBar(
                          //                   content: Text('Added To Favorite'),
                          //                 ));
                          //               },
                          //               child: const Text('Add To Favorite'),
                          //             ),
                          //             SimpleDialogOption(
                          //               onPressed: () {
                          //                 Navigator.of(context,
                          //                         rootNavigator: true)
                          //                     .pop('dialog');
                          //                 Navigator.of(context)
                          //                     .pushNamed('/chats');
                          //               },
                          //               child: const Text('Star Chat'),
                          //             ),
                          //           ],
                          //         );
                          //       });
                          // },
                          child: Card(
                        child: Column(
                          children: <Widget>[
                            Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                        padding: EdgeInsets.all(7.0),
                                        child: Column(children: <Widget>[
                                          Text(
                                              snapshot
                                                  .data.records[index].myName,
                                              textAlign: TextAlign.justify,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 15.0))
                                        ]))
                                  ],
                                )),
                            // _buildImage(),
                            Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.all(7.0),
                                      child: Icon(Icons.attach_money),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(7.0),
                                      child: Text(
                                          'Month: ' +
                                              snapshot.data.records[index].temp2
                                                  .toString(),
                                          style: TextStyle(fontSize: 15.0)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(7.0),
                                      child: Text(
                                          'Daily: ' +
                                              snapshot.data.records[index].temp3
                                                  .toString(),
                                          style: TextStyle(fontSize: 15.0)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(7.0),
                                      child: Text(
                                          'Daily: ' +
                                              snapshot.data.records[index].temp4
                                                  .toString(),
                                          style: TextStyle(fontSize: 15.0)),
                                    )
                                  ],
                                )),
                            Padding(
                                padding: EdgeInsets.all(7.0),
                                child: Row(
                                  children: <Widget>[
                                    Padding(
                                      padding: EdgeInsets.all(7.0),
                                      child: Icon(Icons.access_time),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(7.0),
                                      child: Text(
                                          'Updated At: ' +
                                              snapshot.data.records[index]
                                                  .updateInterval
                                                  .toString(),
                                          style: TextStyle(fontSize: 15.0)),
                                    )
                                  ],
                                ))
                          ],
                        ),
                      ));
                    });
              } else if (snapshot.hasError) {
                return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: 1,
                    itemBuilder: (context, index) {
                      //You need to make my child interactive
                      return Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                                padding: EdgeInsets.all(7.0),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                        padding: EdgeInsets.all(7.0),
                                        child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text('Something Went Wrong :(',
                                                  textAlign: TextAlign.center,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style:
                                                      TextStyle(fontSize: 20.0))
                                            ]))
                                  ],
                                ))
                          ],
                        ),
                      );
                    });
              }
              return CircularProgressIndicator();
            },
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
