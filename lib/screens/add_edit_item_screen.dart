import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? item; // Null means we're adding a new one; non-null means editing

  const AddEditItemScreen({super.key, this.item});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    // Preload data if editing
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.item?.price.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.item?.category ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  // Helper function to return to the first screen (home)
  void _goHome() {
    print('Can pop? ${Navigator.of(context).canPop()}');

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Just pop back one screen
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final category = _categoryController.text.trim().isEmpty
        ? 'Uncategorized'
        : _categoryController.text.trim();

    if (_isEditMode) {
      // Update existing item
      final updated = widget.item!.copyWith(
        name: name,
        quantity: quantity,
        price: price,
        category: category,
      );
      await _firestoreService.updateItem(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Add new item
      final newItem = Item(
        name: name,
        quantity: quantity,
        price: price,
        category: category,
        createdAt: DateTime.now(),
      );
      await _firestoreService.addItem(newItem);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item added successfully!'),
          backgroundColor: Colors.blue,
        ),
      );
    }

    // Wait briefly so the snackbar appears before navigating
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) _goHome();
  }

  Future<void> _deleteItem() async {
    if (widget.item?.id == null) return;

    await _firestoreService.deleteItem(widget.item!.id!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item deleted successfully!'),
        backgroundColor: Colors.red,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Item' : 'Add Item'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteItem,
              tooltip: 'Delete this item',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(val.trim()) == null) {
                    return 'Quantity must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(val.trim()) == null) {
                    return 'Price must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _saveItem,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Save Changes' : 'Add Item'),
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleteItem,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
