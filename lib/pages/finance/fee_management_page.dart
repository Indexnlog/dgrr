import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FeeManagementPage extends StatefulWidget {
  const FeeManagementPage({super.key});

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String selectedYearMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
  List<String> availableYearMonths = [];

  double total = 0;
  double monthTotal = 0;

  String? _teamId;
  bool isManager = false;
  bool isTreasurer = false;

  CollectionReference get _feeCollection => _teamId == null
      ? _firestore.collection('null') // 임시
      : _firestore.collection('teams').doc(_teamId).collection('regular_fees');

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
          isManager = (role == 'manager');
          isTreasurer = (role == 'treasurer');
        });
        _loadAvailableMonths();
        _calculateTotals();
        return;
      }
    }
  }

  Future<void> _loadAvailableMonths() async {
    final snapshot = await _feeCollection.get();
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

  Future<void> _calculateTotals() async {
    final snapshot = await _feeCollection.get();
    double totalSum = 0;
    double monthlySum = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = (data['date'] as Timestamp).toDate();
      final ym = "${ts.year}-${ts.month.toString().padLeft(2, '0')}";
      final amt = (data['amount'] as num).toDouble();

      totalSum += amt;
      if (ym == selectedYearMonth) monthlySum += amt;
    }

    if (mounted) {
      setState(() {
        total = totalSum;
        monthTotal = monthlySum;
      });
    }
  }

  Future<void> _addFee() async {
    if (_teamId == null) return;
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null) return;

    await _feeCollection.add({
      'teamId': _teamId,
      'date': Timestamp.fromDate(selectedDate),
      'amount': amount,
      'memo': _memoController.text.trim(),
      'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'createdAt': Timestamp.now(),
    });

    _amountController.clear();
    _memoController.clear();
    _calculateTotals();
    _loadAvailableMonths();
  }

  Future<void> _deleteFee(String docId) async {
    await _feeCollection.doc(docId).delete();
    _calculateTotals();
    _loadAvailableMonths();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: 0,
    );

    if (_teamId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('💸 정기 회비 관리')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 월 선택
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
                    setState(() => selectedYearMonth = val);
                    _calculateTotals();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '💰 총 회비 수입: ${formatter.format(total)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '📅 $selectedYearMonth 입금: ${formatter.format(monthTotal)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),

            // 회비 리스트
            StreamBuilder<QuerySnapshot>(
              stream: _feeCollection
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
                      child: ListTile(
                        title: Text(
                          "${DateFormat('yyyy-MM-dd').format(ts)}  회비",
                        ),
                        subtitle: Text(data['memo'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "+${formatter.format(data['amount'])}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isManager || isTreasurer)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteFee(doc.id),
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

            // 회비 추가
            if (isManager || isTreasurer) ...[
              Text('➕ 회비 추가', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '금액'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: '메모 (선택)'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _addFee,
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
