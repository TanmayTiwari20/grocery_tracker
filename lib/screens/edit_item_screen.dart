import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/grocery_database.dart';
import '../models/grocery_item.dart';

class EditItemScreen extends StatefulWidget {
  final GroceryItem item;
  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(text: widget.item.quantity);
    _selectedDate = widget.item.expiryDate;
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      final updatedItem = widget.item.copyWith(
        name: _nameController.text.trim(),
        quantity: _quantityController.text.trim(),
        expiryDate: _selectedDate,
      );

      await GroceryDatabase.instance.updateItem(updatedItem);
      Navigator.pop(context); // back to home
    }
  }

  Future<void> _deleteItem() async {
    await GroceryDatabase.instance.deleteItem(widget.item.id!);
    Navigator.pop(context); // back to home
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
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
      appBar: AppBar(
        title: Text('Edit Grocery'),
        actions: [IconButton(icon: Icon(Icons.delete), onPressed: _deleteItem)],
      ),
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
                  Text(DateFormat.yMMMd().format(_selectedDate)),
                  Spacer(),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: Text('Pick Expiry Date'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _updateItem,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
