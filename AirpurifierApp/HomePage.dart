//2024-08-15 기능 완성

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:airpurifier_fin/ManageColor.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: Center(
              child: Column(
                children: [
                  const Text("Home", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  Text("메인 페이지", style: TextStyle(fontSize: 15, color: Colors.grey[400], height: 0.3)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Firestore에서 데이터 가져오기
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.doc('data/3Wq2vm2jtPYezllO3lyp').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(); //빈 컨테이너 반환 (원래 회전하는 로딩창이었는데 잔상이 남아서 수정함)
              }

              // Firestore에서 데이터 가져오기
              var data = snapshot.data!.data() as Map<String, dynamic>;
              int pm25 = data['FineDustCondition']; // 미세먼지 농도
              int filterUsage = data['FilterUsingDuration']; // 필터 사용 기간

              if(pm25>=1000) pm25=999; //1000부터는 칸을 넘김

              // 빌드가 완료된 후에 상태 업데이트
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if(pm25 <= 15)
                  Provider.of<ColorProvider>(context, listen: false).setPM25Color(const Color.fromARGB(255, 73, 206, 221));
                else if(pm25 <= 35)
                  Provider.of<ColorProvider>(context, listen: false).setPM25Color(const Color.fromARGB(255, 95, 197, 98));
                else if(pm25 <= 75)
                  Provider.of<ColorProvider>(context, listen: false).setPM25Color(const Color.fromARGB(255, 235, 162, 60));
                else
                  Provider.of<ColorProvider>(context, listen: false).setPM25Color(Colors.redAccent);

                if(filterUsage <= 120)
                  Provider.of<ColorProvider>(context, listen: false).setfilterColor(const Color.fromARGB(255, 73, 206, 221));
                else if(filterUsage <= 240)
                  Provider.of<ColorProvider>(context, listen: false).setfilterColor(const Color.fromARGB(255, 95, 197, 98));
                else if(filterUsage <= 365)
                  Provider.of<ColorProvider>(context, listen: false).setfilterColor(const Color.fromARGB(255, 235, 162, 60));
                else
                  Provider.of<ColorProvider>(context, listen: false).setfilterColor(Colors.redAccent);
              });

              return Column(
                children: [
                  // 미세먼지 농도 표시
                  Consumer<ColorProvider>(
                    builder: (context, colorProvider, child) {
                      return Container(
                        height: 400,
                        width: 380,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        decoration: BoxDecoration(
                          color: colorProvider.PM25Color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            width: 2,
                            color: Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "현재 초미세먼지",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Colors.white, thickness: 1.8),
                            Row(
                              children: [
                                const Icon(Icons.air, color: Colors.white, size: 80),
                                const SizedBox(width: 18),
                                Text(
                                  "초미세먼지 $pm25㎍/m³",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // 필터 사용 기간 표시
                  Consumer<ColorProvider>(
                    builder: (context, colorProvider, child) {
                      return Container(
                        height: 200,
                        width: 380,
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        decoration: BoxDecoration(
                          color: colorProvider.filterColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            width: 2,
                            color: Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "필터 사용 기간",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Colors.white, thickness: 1.8),
                            Text(
                              "현재 $filterUsage일동안 필터를 \n사용했습니다.",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
