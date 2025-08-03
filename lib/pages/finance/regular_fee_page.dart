import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class RegularFeePage extends StatefulWidget {
  const RegularFeePage({super.key});

  @override
  State<RegularFeePage> createState() => _RegularFeePageState();
}

class _RegularFeePageState extends State<RegularFeePage> {
  final _firestore = FirebaseFirestore.instance;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  String? _teamId;
  bool isManager = false;

  DateTime selectedDate = DateTime.now();
  String selectedYearMonth = _currentYearMonth();
  List<String> availableYearMonths = [];
  int monthlyTotal = 0;

  static String _currentYearMonth() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  @override
  void initState() {
    super.initState();
    _loadTeamIdAndRole();
  }

  Future<void> _loadTeamIdAndRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final teamsSnapshot = await _firestore.collection('teams').get();
    for (var doc in teamsSnapshot.docs) {
      final memberDoc = await doc.reference
          .collection('members')
          .doc(uid)
          .get();
      if (memberDoc.exists) {
        final role = memberDoc['role'] ?? '';
        setState(() {
          _teamId = doc.id;
          isManager = (role == 'treasurer');
        });
        _loadAvailableMonths(doc.id);
        return;
      }
    }
  }

  Future<void> _loadAvailableMonths(String teamId) async {
    final snapshot = await _firestore
        .collection('teams')
        .doc(teamId)
        .collection('regular_fees')
        .get();

    final months = <String>{};
    for (var doc in snapshot.docs) {
      final ts = (doc['date'] as Timestamp).toDate();
      months.add("${ts.year}-${ts.month.toString().padLeft(2, '0')}");
    }

    months.add(selectedYearMonth);

    setState(() {
      availableYearMonths = months.toList()..sort();
    });
  }

  Future<void> _addRegularFee() async {
    if (_teamId == null) return;

    final amount = int.tryParse(_amountController.text);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('금액을 정확히 입력해주세요')));
      return;
    }

    await _firestore
        .collection('teams')
        .doc(_teamId)
        .collection('regular_fees')
        .add({
          'teamId': _teamId,
          'date': Timestamp.fromDate(selectedDate),
          'amount': amount,
          'memo': _memoController.text.trim(),
          'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        });

    _amountController.clear();
    _memoController.clear();
    _loadAvailableMonths(_teamId!);
  }

  Future<void> _deleteRegularFee(String docId) async {
    if (_teamId == null) return;
    await _firestore
        .collection('teams')
        .doc(_teamId)
        .collection('regular_fees')
        .doc(docId)
        .delete();

    _loadAvailableMonths(_teamId!);
  }

  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs) async {
    final buffer = StringBuffer();
    buffer.writeln("날짜,금액,메모");

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = data['amount'] ?? 0;
      final memo = data['memo'] ?? '';
      buffer.writeln("${DateFormat('yyyy-MM-dd').format(date)},$amount,$memo");
    }

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/regular_fees_$selectedYearMonth.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    await Share.shareXFiles([XFile(path)], text: '정기 회비 내역');
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: 0,
    );

    if (_teamId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('💸 정기 회비 관리')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('teams')
            .doc(_teamId)
            .collection('regular_fees')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs.where((doc) {
            final ts = (doc['date'] as Timestamp).toDate();
            final ym = "${ts.year}-${ts.month.toString().padLeft(2, '0')}";
            return ym == selectedYearMonth;
          }).toList();

          monthlyTotal = docs.fold<int>(
            0,
            (sum, doc) => sum + ((doc['amount'] ?? 0) as int),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📅 월 선택:'),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: selectedYearMonth,
                      items: availableYearMonths
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedYearMonth = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Text(
                  '총합: ${currencyFormatter.format(monthlyTotal)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Divider(height: 32),

                if (docs.isEmpty)
                  const Text('해당 월에는 회비 기록이 없습니다.')
                else
                  Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final ts = (data['date'] as Timestamp).toDate();
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(
                            "${DateFormat('yyyy-MM-dd').format(ts)} 정기 회비",
                          ),
                          subtitle: Text(data['memo'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormatter.format(data['amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isManager)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteRegularFee(doc.id),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 16),
                if (docs.isNotEmpty)
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('CSV로 저장'),
                      onPressed: () => _exportToCSV(docs),
                    ),
                  ),

                const Divider(height: 32),

                if (isManager) ...[
                  Text(
                    '➕ 정기 회비 추가',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
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
                    onPressed: _addRegularFee,
                    icon: const Icon(Icons.save),
                    label: const Text('저장'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
