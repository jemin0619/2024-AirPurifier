import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:provider/provider.dart';
import 'package:airpurifier_fin/ManageButton.dart';

class Settingpage extends StatefulWidget {
  const Settingpage({super.key});
  
  @override
  State<Settingpage> createState() => _SettingpageState();
}

class _SettingpageState extends State<Settingpage> {

  @override
  Widget build(BuildContext context) {
    final switchProvider = Provider.of<SwitchProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: Center(
                child: Column(
                  children: [
                    const Text("Settings", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, )),
                    Text("공기청정기 상태 설정", style: TextStyle(fontSize: 15, color: Colors.grey[400], height: 0.3))
                  ],
                )
              ),
            ),
            const SizedBox(height: 10),

            Column(
              children: [
                const Divider(color: Colors.grey, indent: 10, endIndent: 10, thickness: 0.2),
                Container(
                  height: 100,
                  width: 380,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("수동 모드",
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold
                            )
                          ),
                          Text("팬 속도를 직접 조정합니다.",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w200
                            )
                          )
                        ],
                      ),
                      const SizedBox(width: 30),
                      AdvancedSwitch(
                        controller: ValueNotifier<bool>(switchProvider.isActive),
                        activeColor: Colors.green,
                        inactiveColor: Colors.grey,
                        activeChild: const Text('ON', style: TextStyle(color: Colors.white, fontSize: 20)),
                        inactiveChild: const Text('OFF', style: TextStyle(color: Colors.black, fontSize: 20)),
                        borderRadius: BorderRadius.circular(20),
                        width: 150.0,
                        height: 70.0,
                        initialValue: switchProvider.isActive,
                        onChanged: (value) {
                          switchProvider.setSwitch(value);
                        },
                      ),
                    ],
                  )
                ),
                const Divider(color: Colors.grey, indent: 10, endIndent: 10, thickness: 0.2),
                const SizedBox(height: 60),
                const Divider(color: Colors.grey, indent: 10, endIndent: 10, thickness: 0.2),
                
                Consumer<SwitchProvider>(
                  builder: (context, SWP, child){
                    return Container(
                      height: 400,
                      width: 380,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child:  Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("팬 속도 조절",
                            style: TextStyle(
                              fontSize: 35,
                              fontWeight: FontWeight.bold,
                              color: SWP.color
                            ),
                          ),
                          Text("4가지 단계로 속도를 조절합니다",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w200,
                              color: SWP.color
                            )
                          )
                        ],
                      ),
                    );
                  }
                ),
                const Divider(color: Colors.grey, indent: 10, endIndent: 10, thickness: 0.2),
              ],
            )
          ],
        ),
      ),
    );
  }
}
