import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class AddEditItemScreen extends StatefulWidget {
  final Item? item;

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

  String _selectedCategory = 'Uncategorized';
  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    // Preload existing data if editing
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '',
    );
    _priceController = TextEditingController(
      text: widget.item?.price.toString() ?? '',
    );
    _selectedCategory = widget.item?.category ?? 'Uncategorized';
  }

  // Helper to safely return home (used after saving or deleting)
  void _goHome() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // Handles both adding and editing an item
  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (_isEditMode) {
      // Update existing item
      final updated = widget.item!.copyWith(
        name: name,
        quantity: quantity,
        price: price,
        category: _selectedCategory,
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
        category: _selectedCategory,
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

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _goHome();
  }

  // Delete item
  Future<void> _deleteItem() async {
    if (widget.item?.id == null) return;
    await _firestoreService.deleteItem(widget.item!.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item deleted!'),
        backgroundColor: Colors.red,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) _goHome();
  }

  // Opens dialog to create a new category
  Future<void> _addNewCategory() async {
    final newCategory = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String name = '';
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Category name',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => name = val.trim(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, name),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      await _firestoreService.addCategory(newCategory);
      setState(() => _selectedCategory = newCategory);
    }
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),

              // Quantity
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter quantity';
                  if (int.tryParse(v) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter price';
                  if (double.tryParse(v) == null) return 'Must be numeric';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Category Dropdown (safe fix applied here)
              StreamBuilder<List<Category>>(
                stream: _firestoreService.getCategoriesStream(),
                builder: (context, snapshot) {
                  final categories = snapshot.data ?? [];

                  // Always ensure 'Uncategorized' exists
                  final allCats = [
                    Category(id: 'none', name: 'Uncategorized'),
                    ...categories,
                  ];

                  final items = [
                    ...allCats.map(
                      (c) =>
                          DropdownMenuItem(value: c.name, child: Text(c.name)),
                    ),
                    const DropdownMenuItem(
                      value: 'add_new',
                      child: Text('➕ Add new category'),
                    ),
                  ];

                  // Fallback: reset if value isn’t in the dropdown
                  if (!allCats.any((c) => c.name == _selectedCategory)) {
                    _selectedCategory = 'Uncategorized';
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: items,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) async {
                      if (val == 'add_new') {
                        await _addNewCategory();
                      } else if (val != null) {
                        setState(() => _selectedCategory = val);
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 18),

              // Save / Add button
              ElevatedButton.icon(
                onPressed: _saveItem,
                icon: const Icon(Icons.save),
                label: Text(_isEditMode ? 'Save Changes' : 'Add Item'),
              ),

              // Delete button for edit mode
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _deleteItem,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Item'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
