//https://esoog.tistory.com/entry/%ED%94%8C%EB%9F%AC%ED%84%B0flutter-%EB%B8%94%EB%A3%A8%ED%88%AC%EC%8A%A4bluetooth
//flutter_bluetooth_serial 자료가 많지 않아 이 글을 토대로 코드를 수정하고 있습니다.

//setstate가 많이 쓰이는 것을 알 수 있는데, 이는 StatefulWidget에서 변수를 변경하기 위한 명령어이다.
//변수의 변화가 UI의 변화에 영향을 미칠 수 있게 해준다.

//Future<>는 일정 시간이 지난 후 실제 데이터 값이나 에러를 반환한다.
//Future<void>는 일정 시간 후에 값을 받아와서 처리해야 하는 경우 사용하는 것 같다.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

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

class BluetoothSearchScreen extends StatefulWidget {
  @override
  _BluetoothSearchScreenState createState() => _BluetoothSearchScreenState();
}

class _BluetoothSearchScreenState extends State<BluetoothSearchScreen> {
  
  //BluetoochState는 총 5개의 state를 갖고 있다.
  //BluetoothState.UNKNOWN
  //BluetoothState.STATE_OFF
  //BluetoothState.STATE_ON
  //BluetoothState.STATE_TURNING_ON
  //BluetoothState.STATE_TURNING_OFF
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _devicesList = [];
  bool _isLoading = false;
  BluetoothConnection? _connection; // 타입?  nullable 타입을 나타냄.

  @override
  void initState() { //StatefulWidget 생성시 한 번 실행되는 초기화 함수
    super.initState();
    _initBluetooth();
  }

  
  //권한 확인 (스캔, 연결, 위치)
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

  
  //async로 비동기 처리
  //결과를 기다리는 값들은 await로 비동기 처리
  void _initBluetooth() async {
    await _requestPermissions(); //권한 확인

    //스마트폰에서 현재 블루투스의 상태를 가져온다. (상태들은 위에 설명해놓음)
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    //블루투스가 꺼져있으면 켜도록 요청한다.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }
    await _getBondedDevices();
  }

  
  //연결할 수 있는 디바이스를 리스트에 담고, setState로 _deviceList에 반영한다.
  Future<void> _getBondedDevices() async {
    List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {
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
      if (isConnected) await FlutterBluetoothSerial.instance.disconnect();

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

  //Bluetooth Search Screen UI 설정
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bluetooth',
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
              child: Text(_isLoading ? '검색 취소' : '블루투스 스캔'),
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

/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////

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

/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////
