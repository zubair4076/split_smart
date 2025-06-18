import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../services/expense_service.dart';
import '../../services/group_service.dart';
import '../../services/auth_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart';

class GroupExpenseScreen extends StatefulWidget {
  final GroupModel group;
  const GroupExpenseScreen({super.key, required this.group});

  @override
  State<GroupExpenseScreen> createState() => _GroupExpenseScreenState();
}

class _GroupExpenseScreenState extends State<GroupExpenseScreen> {
  late GroupModel _group;
  List<UserModel> _members = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final groupService = GroupService();
      final members = await groupService.getGroupMembers(_group.id);
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        group: _group,
        members: _members,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    final isAdmin = currentUser != null && currentUser.uid == _group.adminId;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_group.name} Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Export',
            onPressed: _showExportDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: _buildDashboard(),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<ExpenseModel>>(
                    stream: ExpenseService().getGroupExpenses(_group.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Card(
                            color: Colors.red[50],
                            margin: const EdgeInsets.all(24),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Could not load expenses.',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'A database error occurred. Please try again or check your Firestore indexes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.red[700]),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Try Again'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final expenses = snapshot.data ?? [];
                      if (expenses.isEmpty) {
                        return const Center(child: Text('No expenses yet.'));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          final paidBy = _members.firstWhere(
                            (m) => m.id == expense.paidBy,
                            orElse: () => UserModel(
                              id: '',
                              email: '',
                              username: 'Unknown',
                              groupIds: [],
                              createdAt: DateTime.now(),
                              lastLogin: DateTime.now(),
                            ),
                          );
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                child: const Icon(Icons.attach_money, color: Colors.blue),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Amount: ${expense.amount.toStringAsFixed(2)}'),
                                  Text('Paid by: ${paidBy.username}'),
                                  Text('Date: ${expense.date.toLocal().toString().split(' ')[0]}'),
                                  if (expense.notes != null && expense.notes!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.note, size: 16, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(expense.notes!)),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isAdmin) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showEditExpenseDialog(expense),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _confirmDeleteExpense(expense),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Balances:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ..._group.memberBalances.entries.map((entry) {
                            final member = _members.firstWhere(
                              (m) => m.id == entry.key,
                              orElse: () => UserModel(
                                id: '',
                                email: '',
                                username: 'Unknown',
                                groupIds: [],
                                createdAt: DateTime.now(),
                                lastLogin: DateTime.now(),
                              ),
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    child: const Icon(Icons.person, size: 16, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    member.username,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(entry.value.toStringAsFixed(2)),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          const Text('Settlement:', style: TextStyle(fontWeight: FontWeight.bold)),
                          ..._buildSettlementSummary(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddExpenseDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Expense'),
            ),
    );
  }

  List<Widget> _buildSettlementSummary() {
    // Calculate who owes whom using a greedy algorithm
    final balances = Map<String, double>.from(_group.memberBalances);
    final List<_Settlement> settlements = [];
    final List<String> memberIds = balances.keys.toList();
    // Split into creditors and debtors
    final creditors = <String, double>{};
    final debtors = <String, double>{};
    for (final id in memberIds) {
      final bal = balances[id] ?? 0.0;
      if (bal > 0.01) {
        creditors[id] = bal;
      } else if (bal < -0.01) {
        debtors[id] = -bal;
      }
    }
    final getName = (String id) => _members.firstWhere((m) => m.id == id, orElse: () => UserModel(id: '', email: '', username: 'Unknown', groupIds: [], createdAt: DateTime.now(), lastLogin: DateTime.now())).username;
    final tol = 0.01;
    final credList = creditors.entries.toList();
    final debtList = debtors.entries.toList();
    int i = 0, j = 0;
    while (i < debtList.length && j < credList.length) {
      final debtorId = debtList[i].key;
      final creditorId = credList[j].key;
      final debt = debtList[i].value;
      final credit = credList[j].value;
      final settled = debt < credit ? debt : credit;
      if (settled > tol) {
        settlements.add(_Settlement(
          from: getName(debtorId),
          to: getName(creditorId),
          amount: settled,
        ));
      }
      debtList[i] = MapEntry(debtorId, debt - settled);
      credList[j] = MapEntry(creditorId, credit - settled);
      if (debtList[i].value <= tol) i++;
      if (credList[j].value <= tol) j++;
    }
    if (settlements.isEmpty) {
      return [const Text('All settled up!')];
    }
    return settlements
        .map((s) => Text('${s.from} owes ${s.to}: ${s.amount.toStringAsFixed(2)}'))
        .toList();
  }

  void _showEditExpenseDialog(ExpenseModel expense) {
    showDialog(
      context: context,
      builder: (context) => EditExpenseDialog(
        group: _group,
        members: _members,
        expense: expense,
      ),
    );
  }

  void _confirmDeleteExpense(ExpenseModel expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ExpenseService().deleteExpense(expense.id);
    }
  }

  Widget _buildDashboard() {
    // Calculate total expenses, individual share, balances, and borrows
    // We'll use the current _group and _members
    double totalExpenses = 0;
    int memberCount = _members.length;
    Map<String, double> memberPaid = {for (var m in _members) m.id: 0.0};
    Map<String, double> memberOwes = {for (var m in _members) m.id: 0.0};
    // Get all expenses for this group (from ExpenseService)
    // We'll use a FutureBuilder to get the latest expenses
    return FutureBuilder<List<ExpenseModel>>(
      future: ExpenseService().getGroupExpenses(_group.id).first,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final expenses = snapshot.data!;
        for (var exp in expenses) {
          totalExpenses += exp.amount;
          memberPaid[exp.paidBy] = (memberPaid[exp.paidBy] ?? 0) + exp.amount;
          exp.splits.forEach((uid, split) {
            memberOwes[uid] = (memberOwes[uid] ?? 0) + split;
          });
        }
        final individualShare = memberCount > 0 ? totalExpenses / memberCount : 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Expenses:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(totalExpenses.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Individual Share:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(individualShare.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const Text('Your Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._members.map((m) {
              final paid = memberPaid[m.id] ?? 0.0;
              final owes = memberOwes[m.id] ?? 0.0;
              final balance = paid - owes;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      child: const Icon(Icons.person, size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Text(m.username, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text(balance >= 0 ? '+${balance.toStringAsFixed(2)}' : balance.toStringAsFixed(2),
                        style: TextStyle(color: balance >= 0 ? Colors.green : Colors.red)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            const Divider(),
            const Text('Individual Borrows:', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._members.map((m) {
              final owes = memberOwes[m.id] ?? 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      child: const Icon(Icons.person, size: 16, color: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    Text(m.username, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    Text(owes.toStringAsFixed(2)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showExportDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Expenses'),
        content: const Text('Choose a format to export:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportAsPDF();
            },
            child: const Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _exportAsExcel();
            },
            child: const Text('Excel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsPDF() async {
    final pdf = pw.Document();
    final expenses = await ExpenseService().getGroupExpenses(_group.id).first;
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('${_group.name} - Expenses', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: ['Title', 'Amount', 'Paid By', 'Date', 'Notes'],
            data: expenses.map((e) => [
              e.title,
              e.amount.toStringAsFixed(2),
              _members.firstWhere((m) => m.id == e.paidBy, orElse: () => UserModel(id: '', email: '', username: 'Unknown', groupIds: [], createdAt: DateTime.now(), lastLogin: DateTime.now())).username,
              e.date.toLocal().toString().split(' ')[0],
              e.notes ?? '',
            ]).toList(),
          ),
        ],
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${_group.name}_expenses.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)], text: 'Group expenses for ${_group.name}');
  }

  Future<void> _exportAsExcel() async {
    final excel = Excel.createExcel();
    final sheet = excel['Expenses'];
    final expenses = await ExpenseService().getGroupExpenses(_group.id).first;
    sheet.appendRow(['Title', 'Amount', 'Paid By', 'Date', 'Notes']);
    for (var e in expenses) {
      sheet.appendRow([
        e.title,
        e.amount.toStringAsFixed(2),
        _members.firstWhere((m) => m.id == e.paidBy, orElse: () => UserModel(id: '', email: '', username: 'Unknown', groupIds: [], createdAt: DateTime.now(), lastLogin: DateTime.now())).username,
        e.date.toLocal().toString().split(' ')[0],
        e.notes ?? '',
      ]);
    }
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/${_group.name}_expenses.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await Share.shareXFiles([XFile(file.path)], text: 'Group expenses for ${_group.name}');
  }
}

class AddExpenseDialog extends StatefulWidget {
  final GroupModel group;
  final List<UserModel> members;
  const AddExpenseDialog({super.key, required this.group, required this.members});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  UserModel? _selectedPayer;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _error;
  bool _customSplit = false;
  Map<String, TextEditingController> _customSplitControllers = {};

  @override
  void initState() {
    super.initState();
    if (widget.members.isNotEmpty) {
      _selectedPayer = widget.members.first;
    }
    for (var m in widget.members) {
      _customSplitControllers[m.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var c in _customSplitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate() || _selectedPayer == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final amount = double.parse(_amountController.text.trim());
      Map<String, double> splits;
      if (_customSplit) {
        double total = 0;
        splits = {};
        for (var m in widget.members) {
          final val = _customSplitControllers[m.id]?.text.trim() ?? '0';
          final splitAmt = double.tryParse(val) ?? 0.0;
          splits[m.id] = splitAmt;
          total += splitAmt;
        }
        if ((total - amount).abs() > 0.01) {
          setState(() {
            _error = 'Custom split total must equal the expense amount.';
            _isLoading = false;
          });
          return;
        }
      } else {
        final splitAmount = amount / widget.members.length;
        splits = {for (var m in widget.members) m.id: splitAmount};
      }
      await ExpenseService().createExpense(
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        amount: amount,
        paidBy: _selectedPayer!.id,
        notes: _notesController.text.trim(),
        splits: splits,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.add_circle_outline, color: Colors.blue),
          SizedBox(width: 8),
          Text('Add Expense'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  final n = num.tryParse(value);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserModel>(
                value: _selectedPayer,
                items: widget.members
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.username),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPayer = val),
                decoration: const InputDecoration(labelText: 'Paid By', prefixIcon: Icon(Icons.person)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _customSplit,
                    onChanged: (val) => setState(() => _customSplit = val ?? false),
                  ),
                  const Text('Custom Split'),
                ],
              ),
              if (_customSplit)
                Column(
                  children: widget.members
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextFormField(
                              controller: _customSplitControllers[m.id],
                              decoration: InputDecoration(
                                labelText: 'Amount for ${m.username}',
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (!_customSplit) return null;
                                if (value == null || value.isEmpty) return 'Enter amount';
                                final n = num.tryParse(value);
                                if (n == null) return 'Enter a valid number';
                                if (n < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ))
                      .toList(),
                ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addExpense,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Add'),
        ),
      ],
    );
  }
}

class EditExpenseDialog extends StatefulWidget {
  final GroupModel group;
  final List<UserModel> members;
  final ExpenseModel expense;
  const EditExpenseDialog({super.key, required this.group, required this.members, required this.expense});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  UserModel? _selectedPayer;
  late DateTime _selectedDate;
  bool _isLoading = false;
  String? _error;
  bool _customSplit = false;
  Map<String, TextEditingController> _customSplitControllers = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _notesController = TextEditingController(text: widget.expense.notes ?? '');
    _selectedPayer = widget.members.firstWhere((m) => m.id == widget.expense.paidBy, orElse: () => widget.members.first);
    _selectedDate = widget.expense.date;
    _customSplit = !_isEqualSplit(widget.expense.splits, widget.expense.amount, widget.members.length);
    for (var m in widget.members) {
      _customSplitControllers[m.id] = TextEditingController(text: widget.expense.splits[m.id]?.toString() ?? '0');
    }
  }

  bool _isEqualSplit(Map<String, double> splits, double amount, int count) {
    final expected = amount / count;
    return splits.values.every((v) => (v - expected).abs() < 0.01);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (var c in _customSplitControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _editExpense() async {
    if (!_formKey.currentState!.validate() || _selectedPayer == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final amount = double.parse(_amountController.text.trim());
      Map<String, double> splits;
      if (_customSplit) {
        double total = 0;
        splits = {};
        for (var m in widget.members) {
          final val = _customSplitControllers[m.id]?.text.trim() ?? '0';
          final splitAmt = double.tryParse(val) ?? 0.0;
          splits[m.id] = splitAmt;
          total += splitAmt;
        }
        if ((total - amount).abs() > 0.01) {
          setState(() {
            _error = 'Custom split total must equal the expense amount.';
            _isLoading = false;
          });
          return;
        }
      } else {
        final splitAmount = amount / widget.members.length;
        splits = {for (var m in widget.members) m.id: splitAmount};
      }
      await ExpenseService().updateExpense(widget.expense.id, {
        'title': _titleController.text.trim(),
        'amount': amount,
        'paidBy': _selectedPayer!.id,
        'notes': _notesController.text.trim(),
        'splits': splits,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.edit, color: Colors.blue),
          SizedBox(width: 8),
          Text('Edit Expense'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter an amount';
                  final n = num.tryParse(value);
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Amount must be positive';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserModel>(
                value: _selectedPayer,
                items: widget.members
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.username),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPayer = val),
                decoration: const InputDecoration(labelText: 'Paid By', prefixIcon: Icon(Icons.person)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text(_selectedDate.toLocal().toString().split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
              Row(
                children: [
                  Checkbox(
                    value: _customSplit,
                    onChanged: (val) => setState(() => _customSplit = val ?? false),
                  ),
                  const Text('Custom Split'),
                ],
              ),
              if (_customSplit)
                Column(
                  children: widget.members
                      .map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextFormField(
                              controller: _customSplitControllers[m.id],
                              decoration: InputDecoration(
                                labelText: 'Amount for ${m.username}',
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (!_customSplit) return null;
                                if (value == null || value.isEmpty) return 'Enter amount';
                                final n = num.tryParse(value);
                                if (n == null) return 'Enter a valid number';
                                if (n < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ))
                      .toList(),
                ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _editExpense,
          child: _isLoading ? const CircularProgressIndicator() : const Text('Save'),
        ),
      ],
    );
  }
}

class _Settlement {
  final String from;
  final String to;
  final double amount;
  _Settlement({required this.from, required this.to, required this.amount});
} 