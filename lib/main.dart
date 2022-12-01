import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

const baseUrl = 'https://gsi-fire-test-server.run.goorm.io/api';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}


Future<Temperature> fetchTemp() async {
  var url_temp = baseUrl + '/status/temperature';
  final response_temp = await http.get(Uri.parse(url_temp));

  if (response_temp.statusCode == 200) {
    //만약 서버가 ok응답을 반환하면, json을 파싱합니다
    print('응답했다');
    return Temperature.fromJson(json.decode(response_temp.body));
  } else {
    //만약 응답이 ok가 아니면 에러를 던집니다.
    throw Exception('정보를 불러오는데 실패했습니다');
  }
}

Future<Box> fetchBox() async {
  var url_box = baseUrl + '/status/box';
  final response_box = await http.get(Uri.parse(url_box));

  if (response_box.statusCode == 200) {
    //만약 서버가 ok응답을 반환하면, json을 파싱합니다
    print('응답했다');
    return Box.fromJson(json.decode(response_box.body));
  } else {
    //만약 응답이 ok가 아니면 에러를 던집니다.
    throw Exception('정보를 불러오는데 실패했습니다');
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  runApp(InfoPage()); // initiate MyApp as StatelessWidget
}

// Main class

class Temperature {

  double temperature;
  String level;
  Temperature({
    required this.temperature,
    required this.level,
  });

  factory Temperature.fromJson(Map<String, dynamic> json) => Temperature(
    temperature: json["temperature"].toDouble(),
    level: json["level"],
  );

  Map<String, dynamic> toJson() => {
    "temperature": temperature,
    "level": level,
  };
}

class Box {
  Box({
    required this.boxOpened,
  });

  bool boxOpened;

  factory Box.fromJson(Map<String, dynamic> json) => Box(
    boxOpened: json["box_opened"],
  );

  Map<String, dynamic> toJson() => {
    "box_opened": boxOpened,
  };
}


class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  Future<Temperature>? info;
  Future<Temperature>? temp;
  Future<Box>? box;

  String time = "";
  Color textColor = Colors.black;
  Color textColorBox = Colors.black;

  @override
  void initState() {
    Timer mytimer = Timer.periodic(Duration(seconds: 1), (timer) {
      DateTime timenow = DateTime.now();  //get current date and time
      time = timenow.hour.toString() + ":" + timenow.minute.toString() + ":" + timenow.second.toString();
      setState(() {
        temp = fetchTemp();
        box = fetchBox();
      });
    });
    super.initState();
    // info = fetchInfo();
  }

  Future<void> _refresh() async {
    setState(() {
      temp = fetchTemp();
      box = fetchBox();
    });

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "App",
      home: Scaffold(
          appBar: AppBar(
            title: Text('info', style: TextStyle(color: Colors.white)),
            centerTitle: true,
          ),
          body: Center(
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: 1,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Center(
                      child: FutureBuilder<Temperature>(
                        //통신데이터 가져오기
                        future: temp,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return buildColumn(snapshot);
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}에러!!");
                          }
                          return CircularProgressIndicator();
                        },
                      ),
                    ),
                    Center(
                      child: FutureBuilder<Box>(
                        future: box,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return buildBoxColumn(snapshot);
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}에러!!");
                          }
                          return CircularProgressIndicator();
                        },
                      ),
                    )
                  ],
                );
              }
            ),
          )),
    );
  }
  Widget buildColumn(snapshot) {
    switch (snapshot.data!.level.toString()) {
      case "C": {
        textColor = Colors.red;
      }
      break;
      case "B": {
        textColor = Colors.amber;
      }
      break;
      case "A": {
        textColor = Colors.blueAccent;
      }
      break;
      default: {
        textColor = Colors.black;
      }
      break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('현재 시간:' + time,
            style: TextStyle(fontSize: 60, color: textColor)),
        Text('level:' + snapshot.data!.level.toString(),
            style: TextStyle(fontSize: 60, color: textColor)),
        Text('Temperature:' + snapshot.data!.temperature.toString(),
            style: TextStyle(fontSize: 60, color: textColor)),
      ],
    );

  }

  Widget buildBoxColumn(snapshot) {
    String boxStatus = "";

    switch (snapshot.data!.boxOpened) {
      case true:
        {
          boxStatus = "열림";
          textColorBox = Colors.red;
        }break;
      default:
        {
          boxStatus = "닫힘";
          textColorBox = Colors.black;
        }break;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('box:' + boxStatus,
            style: TextStyle(fontSize: 60, color: textColorBox)),
      ],
    );
  }
}
