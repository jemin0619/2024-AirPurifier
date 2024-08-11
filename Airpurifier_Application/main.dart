//https://esoog.tistory.com/entry/%ED%94%8C%EB%9F%AC%ED%84%B0flutter-%EB%B8%94%EB%A3%A8%ED%88%AC%EC%8A%A4bluetooth
//flutter_bluetooth_serial 자료가 많지 않아 이 글을 토대로 코드를 수정하고 있습니다.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothSearchScreen extends StatefulWidget {
  // 스테이트풀 상속.
  @override
  // createState() 메서드가 StatefulWidget의 createState() 메서드를 재정의
  _BluetoothSearchScreenState createState() => _BluetoothSearchScreenState();
//   다트에서 _ (언더바) 는 private 제어자를 말함.
}

class _BluetoothSearchScreenState extends State<BluetoothSearchScreen> {
  // 그리고 스테이트풀 특성상 아래에서 이런 형태로 상수, 변수 정의
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // enum 값 중 unknown
  List<BluetoothDevice> _devicesList = [];
  bool _isLoading = false;
  BluetoothConnection? _connection;
  // 타입?  nullable 타입을 나타냄.



  @override
  void initState() {
    // 오버라이드로 스테이트풀 위젯 생성시 한 번 실행. 초기화 함수
    super.initState();
    _initBluetooth();
  }

  /*
  void _initBluetooth() async {
    // 함수 뒤 async는 비동기적으로 처리.(병렬)
    // 그 결과를 기다리는 값들은 await로 기다림
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    await _getBondedDevices();
  }
  */

  /////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////
  Future<void> _requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse, // 위치 권한도 필요
  ].request();

  if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
      statuses[Permission.bluetoothConnect] != PermissionStatus.granted ||
      statuses[Permission.locationWhenInUse] != PermissionStatus.granted) {
    // 권한이 거부되었을 때 처리
    throw Exception('필수 권한이 허용되지 않았습니다.');
  }
}

  void _initBluetooth() async {
  // 권한 요청 추가
  await _requestPermissions();

  _bluetoothState = await FlutterBluetoothSerial.instance.state;

  if (_bluetoothState == BluetoothState.STATE_OFF) {
    await FlutterBluetoothSerial.instance.requestEnable();
  }

  await _getBondedDevices();
}

/////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////

  Future<void> _getBondedDevices() async {
    // Future<void>: 일반 void와 비교하자면 객체로서 반환 값을 처리 할 수 있음.
    List<BluetoothDevice> bondedDevices =
    await FlutterBluetoothSerial.instance.getBondedDevices();

    setState(() {
      // 이 함수는 자체적으로 다시 빌드 시킴
      _devicesList = bondedDevices;
    });
  }

  Future<void> _startDiscovery() async {
  setState(() {
    _isLoading = true;
    _devicesList = [];
  });

  List<String> deviceAddresses = [];
  FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
    setState(() {
      // 장치가 이름이 있고 중복되지 않았을 때만 추가
      if (r.device.name != null && !deviceAddresses.contains(r.device.address)) {
        deviceAddresses.add(r.device.address);
        _devicesList.add(r.device);
      }
    });
  }).onDone(() {
    setState(() {
      _isLoading = false;
    });
  });
}


  Future<void> _cancelDiscovery() async {
    await FlutterBluetoothSerial.instance.cancelDiscovery();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      bool isConnected = await FlutterBluetoothSerial.instance.isConnected;
      if (isConnected) {
        await FlutterBluetoothSerial.instance.disconnect();
      }

      // 페어링 중 메시지 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        // 창 밖을 터치 무시
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('블루투스 연결'),
            content: Text('페어링 중입니다. 잠시 기다려주세요...'),
          );
        },
      );

      _connection = await BluetoothConnection.toAddress(device.address);
      // 연결에 성공한 경우 추가 처리를 수행하세요.
      // 예: 다른 화면으로 이동 또는 연결된 디바이스 정보 저장

      // 페어링 중 메시지 닫기
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendMessageScreen(connection: _connection!),
        ),
      );
    } catch (e) {
      print('연결 중 오류가 발생했습니다: $e');
    }
  }

  Future<void> _disconnectAllDevices() async {
    try {
      if (_connection != null && _connection!.isConnected) {
        await _connection!.finish();
      }
      // 추가적으로 연결된 디바이스가 있다면 여기에 처리를 추가하세요.
    } catch (e) {
      print('연결 해제 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '잠들지 않는 아침',
          textAlign: TextAlign.center,
        ),
        titleTextStyle: TextStyle(color: Colors.black),
        centerTitle: true,
        backgroundColor: Colors.yellow,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _isLoading ? _cancelDiscovery : _startDiscovery,
              child: Text(_isLoading ? '검색 취소' : '블루투스 검색'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devicesList.length,
              itemBuilder: (context, index) {
                BluetoothDevice device = _devicesList[index];
                return ListTile(
                  title: Text(device.name ?? ''),
                  // 값이 있으면 왼쪽 ?? null이면 오른쪽 값
                  subtitle: Text(device.address),
                  onTap: () {
                    _connectToDevice(device);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            // 각 방향 16픽셀 여백 생성
            child: ElevatedButton(
              onPressed: () async {
                await _disconnectAllDevices();
              },
              // 익명의 비동기 함수 콜백
              child: Text('블루투스 연결 끊기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SendMessageScreen extends StatefulWidget {
  final BluetoothConnection connection;

  SendMessageScreen({required this.connection});
  // 필수 요구 매개변수 지정

  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  TextEditingController _messageController1 = TextEditingController();
  TextEditingController _messageController2 = TextEditingController();

  void _sendMessage() async {
    String message1 = _messageController1.text.trim();
    String message2 = _messageController2.text.trim();
    // 공백 제거 함수

    if (message1.isNotEmpty) {
      Uint8List data = Uint8List.fromList(utf8.encode("alarm" + message1 + "\r\n"));
      // 한글로 알아들을 수 있게 인코딩
      widget.connection.output.add(data);
      await widget.connection.output.allSent;
      setState(() {
        _messageController1.clear();
      });
    }
    if (message2.isNotEmpty) {
      Uint8List data = Uint8List.fromList(utf8.encode("settime" + message2 + "\r\n"));
      widget.connection.output.add(data);
      await widget.connection.output.allSent;
      setState(() {
        _messageController2.clear();
      });
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('전송 정보'),
          content: Text('알람 설정: ${_messageController1.text.substring(5,7)}시 ${_messageController1.text.substring(7,9)}분 \n시간 설정: ${_messageController2.text.substring(7,9)}시 ${_messageController2.text.substring(9,11)}분 ${_messageController2.text.substring(11,13)}월 ${_messageController2.text.substring(13,15)}일' ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', textAlign: TextAlign.center),
        titleTextStyle: TextStyle(color: Colors.black),
        centerTitle: true, // 텍스트를 가운데로 정렬
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _messageController1,
              decoration: InputDecoration(
                labelText: '알람 설정(숫자4자리) = 00시 00분',
              ),
            ),
            TextField(
              controller: _messageController2,
              decoration: InputDecoration(
                labelText: '시간 설정(숫자8자리) = 00시 00분 / 00월 00일',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _sendMessage,
              child: Text('입력 전송'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300], // 버튼 색상 변경
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: BluetoothSearchScreen(),
    theme: ThemeData(
      primaryColor: Colors.yellow, // 앱 테마 색상 변경
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: Colors.black), // 텍스트의 기본색 변경
      ),
    ),
  ));
}
