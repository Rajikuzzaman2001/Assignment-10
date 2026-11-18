
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

// ================= APP START =================

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ================= DATABASE HELPER =================

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('expenses.db');

    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create Database Table

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL
      )
    ''');
  }

  // Insert Expense

  Future<int> insertExpense(Map<String, dynamic> row) async {
    final db = await instance.database;

    return await db.insert('expenses', row);
  }

  // Get All Expenses

  Future<List<Map<String, dynamic>>> queryAllExpenses() async {
    final db = await instance.database;

    return await db.query(
      'expenses',
      orderBy: 'id DESC',
    );
  }

  // Delete Expense

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;

    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  List<Map<String, dynamic>> _expenses = [];

  double _totalExpense = 0.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _refreshData();
  }

  // Refresh Database Data

  Future<void> _refreshData() async {

    final data =
    await DatabaseHelper.instance.queryAllExpenses();

    double total = 0.0;

    for (var item in data) {
      total += (item['amount'] as num).toDouble();
    }

    if (!mounted) return;

    setState(() {
      _expenses = data;
      _totalExpense = total;
      _isLoading = false;
    });
  }

  // Delete Expense

  Future<void> _deleteItem(int id) async {

    await DatabaseHelper.instance.deleteExpense(id);

    await _refreshData();

    if (!mounted) return;

    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(
        content: Text('Expense deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Build Home UI

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Column(
        children: [

          // Total Expense Card

          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.blue.shade200,
              ),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      'Your total spending',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                Text(
                  '\$${_totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),

              ],
            ),
          ),

          // Expense List Title

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 5,
            ),

            child: Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Expense List

          Expanded(

            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )

                : _expenses.isEmpty
                ? const Center(
              child: Text(
                'No expenses added yet!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )

                : ListView.builder(

              itemCount: _expenses.length,

              itemBuilder: (context, index) {

                final expense = _expenses[index];

                return Card(

                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),

                  elevation: 2,

                  child: ListTile(

                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.blue,
                      ),
                    ),

                    title: Text(
                      expense['title'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      'Amount: \$${(expense['amount'] as num).toStringAsFixed(2)}',
                    ),

                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),

                      onPressed: () {
                        _deleteItem(expense['id'] as int);
                      },
                    ),

                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Add Expense Button

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

        onPressed: () async {

          final result = await Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );

          if (result == true) {
            _refreshData();
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}

// ================= ADD EXPENSE SCREEN =================

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController =
  TextEditingController();

  final TextEditingController _amountController =
  TextEditingController();

  bool _isSaving = false;

  // Save Expense Function

  Future<void> _saveExpense() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {

      String title = _titleController.text.trim();

      double amount =
      double.parse(_amountController.text.trim());

      await DatabaseHelper.instance.insertExpense({
        'title': title,
        'amount': amount,
      });

      if (!mounted) return;

      Navigator.pop(context as BuildContext, true);

    } catch (e) {

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(
          content: Text('Error saving expense: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  // Add Expense UI

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Padding(

        padding: const EdgeInsets.all(16),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              const SizedBox(height: 20),

              // Expense Title Field

              TextFormField(

                controller: _titleController,

                decoration: const InputDecoration(
                  labelText: 'Expense Title',
                  hintText: 'Example: Food, Shopping',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an expense title';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Amount Field

              TextFormField(

                controller: _amountController,

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),

                validator: (value) {

                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an amount';
                  }

                  final amount = double.tryParse(value.trim());

                  if (amount == null || !amount.isFinite || amount <= 0) {
                    return 'Amount must be greater than zero';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Save Button

              SizedBox(

                width: double.infinity,
                height: 50,

                child: ElevatedButton(

                  onPressed: _isSaving ? null : _saveExpense,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  child: _isSaving
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    'Save Expense',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
