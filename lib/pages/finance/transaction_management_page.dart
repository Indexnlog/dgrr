import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TransactionManagementPage extends StatefulWidget {
  final String teamId;
  const TransactionManagementPage({super.key, required this.teamId});

  @override
  State<TransactionManagementPage> createState() =>
      _TransactionManagementPageState();
}

class _TransactionManagementPageState extends State<TransactionManagementPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String selectedType = 'income';
  String selectedCategory = '회비수입';
  DateTime selectedDate = DateTime.now();

  String selectedYearMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";
  List<String> availableYearMonths = [];

  double totalBalance = 0;
  double monthBalance = 0;

  bool isManager = false;

  CollectionReference get _collection => FirebaseFirestore.instance.collection(
    'teams/${widget.teamId}/transactions',
  );

  @override
  void initState() {
    super.initState();
    _checkManagerRole();
    _loadAvailableMonths();
    _calculateBalance();
  }

  Future<void> _checkManagerRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final memberDoc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .collection('members')
        .doc(uid)
        .get();

    final role = memberDoc.data()?['role'];
    if (role == 'manager' || role == 'treasurer') {
      setState(() => isManager = true);
    }
  }

  Future<void> _loadAvailableMonths() async {
    final snapshot = await _collection.get();
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

  Future<void> _calculateBalance() async {
    final snapshot = await _collection.get();
    double income = 0, expense = 0, incomeMonth = 0, expenseMonth = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = (data['date'] as Timestamp).toDate();
      final ym = "${ts.year}-${ts.month.toString().padLeft(2, '0')}";
      final amt = (data['amount'] as num).toDouble();

      if (data['type'] == 'income') {
        income += amt;
        if (ym == selectedYearMonth) incomeMonth += amt;
      } else {
        expense += amt;
        if (ym == selectedYearMonth) expenseMonth += amt;
      }
    }

    setState(() {
      totalBalance = income - expense;
      monthBalance = incomeMonth - expenseMonth;
    });
  }

  Future<void> _addTransaction() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null) return;

    await _collection.add({
      'teamId': widget.teamId,
      'date': Timestamp.fromDate(selectedDate),
      'type': selectedType,
      'category': selectedCategory,
      'amount': amount,
      'memo': _memoController.text,
      'createdBy': FirebaseAuth.instance.currentUser!.uid,
    });

    _amountController.clear();
    _memoController.clear();
    _calculateBalance();
    _loadAvailableMonths();
  }

  Future<void> _deleteTransaction(String docId) async {
    await _collection.doc(docId).delete();
    _calculateBalance();
    _loadAvailableMonths();
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.simpleCurrency(
      locale: 'ko_KR',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('📒 회비 입출내역 관리')),
      body: SingleChildScrollView(
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
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => selectedYearMonth = val);
                    _calculateBalance();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '💰 현재 잔액: ${formatter.format(totalBalance)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              '📅 $selectedYearMonth 기준 잔액: ${formatter.format(monthBalance)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),
            StreamBuilder<QuerySnapshot>(
              stream: _collection.orderBy('date', descending: true).snapshots(),
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
                    final sign = data['type'] == 'income' ? '+' : '-';
                    final color = data['type'] == 'income'
                        ? Colors.green
                        : Colors.red;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          data['type'] == 'income'
                              ? Icons.call_received
                              : Icons.call_made,
                          color: color,
                        ),
                        title: Text(
                          "${DateFormat('yyyy-MM-dd').format(ts)}  ${data['category']}",
                        ),
                        subtitle: Text(data['memo'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "$sign${formatter.format(data['amount'])}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            if (isManager)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteTransaction(doc.id),
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
            if (isManager) ...[
              Text('➕ 새 내역 추가', style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  DropdownButton<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('입금')),
                      DropdownMenuItem(value: 'expense', child: Text('출금')),
                    ],
                    onChanged: (v) => setState(() => selectedType = v!),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: const [
                      DropdownMenuItem(value: '회비수입', child: Text('회비수입')),
                      DropdownMenuItem(value: '예비비', child: Text('예비비')),
                      DropdownMenuItem(value: '행사비', child: Text('행사비')),
                      DropdownMenuItem(value: '기타', child: Text('기타')),
                    ],
                    onChanged: (v) => setState(() => selectedCategory = v!),
                  ),
                ],
              ),
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
                onPressed: _addTransaction,
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
