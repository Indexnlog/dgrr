import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../teams/presentation/providers/current_team_provider.dart';
import '../../data/datasources/transaction_remote_data_source.dart';

final transactionDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSource(firestore: FirebaseFirestore.instance);
});
