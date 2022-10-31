import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';


Future<Temperature> fetchInfo() async {
  var baseUrl = 'http://localhost:8000';
  var url = baseUrl '/api/status/temperature';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    //만약 서버가 ok응답을 반환하면, json을 파싱합니다
    print('응답했다');
    return Temperature.fromJson(json.decode(response.body));
  } else {
    //만약 응답이 ok가 아니면 에러를 던집니다.
    throw Exception('정보를 불러오는데 실패했습니다');
  }
}

void main() => runApp(InfoPage()); // initiate MyApp as  StatelessWidget

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

class InfoPage extends StatefulWidget {
  const InfoPage({Key? key}) : super(key: key);

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  Future<Temperature>? info;

  @override
  void initState() {
    super.initState();
    info = fetchInfo();
  }

  Future<void> _refresh() async {
    setState(() {
      info = fetchInfo();
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
          body: RefreshIndicator(
            onRefresh: () => _refresh(),
            child: Center(
              child: ListView.builder(
                physics: AlwaysScrollableScrollPhysics(),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Center(
                    child: FutureBuilder<Temperature>(
                      //통신데이터 가져오기
                      future: info,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return buildColumn(snapshot);
                        } else if (snapshot.hasError) {
                          return Text("${snapshot.error}에러!!");
                        }
                        return CircularProgressIndicator();
                      },
                    ),
                  );
                }
              ),
            ),
          )),
    );
  }
  Widget buildColumn(snapshot) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('level:' + snapshot.data!.level.toString(),
            style: TextStyle(fontSize: 20)),
        Text('Temperature:' + snapshot.data!.temperature.toString(),
            style: TextStyle(fontSize: 20)),

      ],
    );

  }
}
