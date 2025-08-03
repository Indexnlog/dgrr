import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/reservation/reservation_model.dart';
import 'package:intl/intl.dart';

class ReservationForm extends StatefulWidget {
  final String teamId;
  final ReservationModel? initialData;

  const ReservationForm({super.key, required this.teamId, this.initialData});

  @override
  State<ReservationForm> createState() => _ReservationFormState();
}

class _ReservationFormState extends State<ReservationForm> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _date;
  String _startTime = '';
  String _endTime = '';
  String _groundId = '';
  String _reservedForId = '';
  String _reservedForType = 'class';
  String _status = 'reserved';
  String _paymentStatus = 'unpaid';
  String _memo = '';

  final formatter = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _date = data.date.toDate();
      _startTime = data.startTime;
      _endTime = data.endTime;
      _groundId = data.groundId;
      _reservedForId = data.reservedForId;
      _reservedForType = data.reservedForType;
      _status = data.status;
      _paymentStatus = data.paymentStatus;
      _memo = data.memo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialData == null ? '예약 추가' : '예약 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 날짜 선택
              ListTile(
                title: Text(_date == null ? '날짜 선택' : formatter.format(_date!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      _date = picked;
                    });
                  }
                },
              ),

              // 시작 시간
              TextFormField(
                initialValue: _startTime,
                decoration: const InputDecoration(
                  labelText: '시작 시간 (예: 10:00)',
                ),
                onChanged: (val) => _startTime = val,
              ),

              // 종료 시간
              TextFormField(
                initialValue: _endTime,
                decoration: const InputDecoration(
                  labelText: '종료 시간 (예: 12:00)',
                ),
                onChanged: (val) => _endTime = val,
              ),

              // 구장 ID
              TextFormField(
                initialValue: _groundId,
                decoration: const InputDecoration(labelText: '구장 ID'),
                onChanged: (val) => _groundId = val,
              ),

              // 예약 대상 ID
              TextFormField(
                initialValue: _reservedForId,
                decoration: const InputDecoration(labelText: '예약 대상 ID'),
                onChanged: (val) => _reservedForId = val,
              ),

              // 예약 대상 타입
              DropdownButtonFormField<String>(
                value: _reservedForType,
                decoration: const InputDecoration(labelText: '예약 타입'),
                items: const [
                  DropdownMenuItem(value: 'class', child: Text('클래스')),
                  DropdownMenuItem(value: 'match', child: Text('매치')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _reservedForType = val);
                },
              ),

              // 예약 상태
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: '예약 상태'),
                items: const [
                  DropdownMenuItem(value: 'reserved', child: Text('예약됨')),
                  DropdownMenuItem(value: 'cancelled', child: Text('취소됨')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),

              // 결제 상태
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(labelText: '결제 상태'),
                items: const [
                  DropdownMenuItem(value: 'unpaid', child: Text('미납')),
                  DropdownMenuItem(value: 'paid', child: Text('결제 완료')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentStatus = val);
                },
              ),

              // 메모
              TextFormField(
                initialValue: _memo,
                decoration: const InputDecoration(labelText: '메모'),
                onChanged: (val) => _memo = val,
              ),

              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('저장')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_date == null) return;

    final docRef = widget.initialData == null
        ? FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('reservations')
              .doc()
        : FirebaseFirestore.instance
              .collection('teams')
              .doc(widget.teamId)
              .collection('reservations')
              .doc(widget.initialData!.id);

    final data = {
      'date': Timestamp.fromDate(_date!),
      'startTime': _startTime,
      'endTime': _endTime,
      'groundId': _groundId,
      'reservedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
      'reservedForId': _reservedForId,
      'reservedForType': _reservedForType,
      'status': _status,
      'paymentStatus': _paymentStatus,
      'memo': _memo,
      'teamId': widget.teamId,
    };

    await docRef.set(data, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }
}
