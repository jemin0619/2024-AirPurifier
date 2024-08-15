import 'package:flutter/material.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:provider/provider.dart';
import 'package:airpurifier_fin/ManageButton.dart';

class Debugpage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final switchProvider = Provider.of<SwitchProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Advanced Switch Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AdvancedSwitch(
              controller: ValueNotifier<bool>(switchProvider.isActive),
              activeColor: Colors.green,
              inactiveColor: Colors.grey,
              activeChild: Text('ON', style: TextStyle(color: Colors.white)),
              inactiveChild: Text('OFF', style: TextStyle(color: Colors.black)),
              borderRadius: BorderRadius.circular(20),
              width: 80.0,
              height: 40.0,
              initialValue: Provider.of<SwitchProvider>(context, listen: false).isActive,
              onChanged: (value) {
                switchProvider.setSwitch(value);
              },
            ),
            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}
