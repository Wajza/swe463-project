import '../models/transaction.dart';
import 'repository.dart';

class WalletService {
  WalletService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<int> getBalance() async => _repository.balance;
  Future<List<WalletTransaction>> getTransactions() async => List.unmodifiable(_repository.transactions);
}
