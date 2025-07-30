import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ClassFeePage extends StatefulWidget {
  const ClassFeePage({super.key});

  @override
  State<ClassFeePage> createState() => _ClassFeePageState();
}

class _ClassFeePageState extends State<ClassFeePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String selectedYearMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
  List<String> availableYearMonths = [];

  bool get isAdmin {
    const adminUids = ['YOUR_ADMIN_UID']; // ✅ 관리자 UID로 바꿔줘
    return adminUids.contains(FirebaseAuth.instance.currentUser?.uid);
  }

  @override
  void initState() {
    super.initState();
    _loadAvailableMonths();
  }

  Future<void> _loadAvailableMonths() async {
    final snapshot = await _firestore.collection('class_fees').get();
    final months = <String>{};
    for (var doc in snapshot.docs) {
      final ts = (doc['date'] as Timestamp).toDate();
      months.add("${ts.year}-${ts.month.toString().padLeft(2, '0')}");
    }
    setState(() {
      availableYearMonths = months.toList()..sort();
      if (!availableYearMonths.contains(selectedYearMonth)) {
        availableYearMonths.add(selectedYearMonth);
      }
    });
  }

  Future<void> _addClassFee() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null) return;

    await _firestore.collection('class_fees').add({
      'date': Timestamp.fromDate(selectedDate),
      'amount': amount,
      'memo': _memoController.text,
      'createdBy': FirebaseAuth.instance.currentUser!.uid,
    });

    _amountController.clear();
    _memoController.clear();
    _loadAvailableMonths();
  }

  Future<void> _deleteClassFee(String docId) async {
    await _firestore.collection('class_fees').doc(docId).delete();
    _loadAvailableMonths();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('🏫 수업 회비 관리')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 월 선택 ===
            Row(
              children: [
                const Text('📅 월 선택:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedYearMonth,
                  items: availableYearMonths.map((m) {
                    return DropdownMenuItem(value: m, child: Text(m));
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      selectedYearMonth = val;
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 32),

            // === 내역 리스트 ===
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('class_fees')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs.where((doc) {
                  final ts = (doc['date'] as Timestamp).toDate();
                  final ym =
                      "${ts.year}-${ts.month.toString().padLeft(2, '0')}";
                  return ym == selectedYearMonth;
                }).toList();

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = (data['date'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          "${DateFormat('yyyy-MM-dd').format(ts)} 수업 회비",
                        ),
                        subtitle: Text(data['memo'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatter.format(data['amount']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteClassFee(doc.id),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(height: 32),

            // === 입력 영역 ===
            if (isAdmin) ...[
              Text('➕ 수업 회비 추가', style: Theme.of(context).textTheme.titleLarge),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '금액'),
              ),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: '메모 (선택)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addClassFee,
                icon: const Icon(Icons.save),
                label: const Text('저장'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
