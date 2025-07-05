import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/grocery_database.dart';
import '../models/grocery_item.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newItem = GroceryItem(
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        expiryDate: _selectedDate!,
        addedOn: DateTime.now(),
      );

      await GroceryDatabase.instance.insert(newItem);
      Navigator.pop(context); // go back to home screen
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Grocery')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: 'Quantity'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _selectedDate == null
                        ? 'No Date Chosen'
                        : DateFormat.yMMMd().format(_selectedDate!),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: Text('Pick Expiry Date'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(onPressed: _saveItem, child: Text('Save Item')),
            ],
          ),
        ),
      ),
    );
  }
}
