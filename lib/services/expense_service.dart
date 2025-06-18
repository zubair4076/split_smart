import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new expense
  Future<ExpenseModel> createExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required Map<String, double> splits,
    String? notes,
  }) async {
    try {
      final docRef = _firestore.collection('expenses').doc();
      final expense = ExpenseModel(
        id: docRef.id,
        groupId: groupId,
        title: title,
        amount: amount,
        paidBy: paidBy,
        date: DateTime.now(),
        notes: notes,
        splits: splits,
      );

      await docRef.set(expense.toMap());

      // Update group member balances
      await _updateGroupBalances(groupId, paidBy, splits);

      return expense;
    } catch (e) {
      rethrow;
    }
  }

  // Get expense by ID
  Future<ExpenseModel?> getExpense(String expenseId) async {
    try {
      final doc = await _firestore.collection('expenses').doc(expenseId).get();
      if (doc.exists) {
        return ExpenseModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get group expenses
  Stream<List<ExpenseModel>> getGroupExpenses(String groupId) {
    return _firestore
        .collection('expenses')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Update expense
  Future<void> updateExpense(String expenseId, Map<String, dynamic> data) async {
    try {
      final expense = await getExpense(expenseId);
      if (expense != null) {
        // Revert old balances
        await _revertGroupBalances(
          expense.groupId,
          expense.paidBy,
          expense.splits,
        );

        // Update expense
        await _firestore.collection('expenses').doc(expenseId).update(data);

        // Update new balances
        await _updateGroupBalances(
          expense.groupId,
          data['paidBy'] ?? expense.paidBy,
          data['splits'] ?? expense.splits,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      final expense = await getExpense(expenseId);
      if (expense != null) {
        // Revert balances
        await _revertGroupBalances(
          expense.groupId,
          expense.paidBy,
          expense.splits,
        );

        // Delete expense
        await _firestore.collection('expenses').doc(expenseId).delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to update group balances
  Future<void> _updateGroupBalances(
    String groupId,
    String paidBy,
    Map<String, double> splits,
  ) async {
    try {
      final group = await _firestore.collection('groups').doc(groupId).get();
      if (group.exists) {
        final groupData = group.data()!;
        final memberBalances = Map<String, double>.from(groupData['memberBalances']);

        // Update balances
        memberBalances[paidBy] = (memberBalances[paidBy] ?? 0) + splits[paidBy]!;
        for (var entry in splits.entries) {
          if (entry.key != paidBy) {
            memberBalances[entry.key] = (memberBalances[entry.key] ?? 0) - entry.value;
          }
        }

        // Update group document
        await _firestore.collection('groups').doc(groupId).update({
          'memberBalances': memberBalances,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to revert group balances
  Future<void> _revertGroupBalances(
    String groupId,
    String paidBy,
    Map<String, double> splits,
  ) async {
    try {
      final group = await _firestore.collection('groups').doc(groupId).get();
      if (group.exists) {
        final groupData = group.data()!;
        final memberBalances = Map<String, double>.from(groupData['memberBalances']);

        // Revert balances
        memberBalances[paidBy] = (memberBalances[paidBy] ?? 0) - splits[paidBy]!;
        for (var entry in splits.entries) {
          if (entry.key != paidBy) {
            memberBalances[entry.key] = (memberBalances[entry.key] ?? 0) + entry.value;
          }
        }

        // Update group document
        await _firestore.collection('groups').doc(groupId).update({
          'memberBalances': memberBalances,
        });
      }
    } catch (e) {
      rethrow;
    }
  }
} 