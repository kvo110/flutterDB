import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';
import 'inventory_dashboard_screen.dart';

// Displays all inventory items in real-time
class InventoryHomePage extends StatefulWidget {
  final String title;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const InventoryHomePage({
    super.key,
    required this.title,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<InventoryHomePage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryHomePage> {
  final FirestoreService _firestoreService = FirestoreService();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          // Theme toggle (light/dark)
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          // Dashboard shortcut
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InventoryDashboardScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by item name...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          // Category filter (live Firestore stream)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: StreamBuilder<List<Category>>(
              stream: _firestoreService.getCategoriesStream(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                final dropdownItems = [
                  const DropdownMenuItem(
                    value: 'All',
                    child: Text('All Categories'),
                  ),
                  ...categories.map(
                    (cat) => DropdownMenuItem(
                      value: cat.name,
                      child: Text(cat.name),
                    ),
                  ),
                ];

                return DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: dropdownItems,
                  onChanged: (val) =>
                      setState(() => _selectedCategory = val ?? 'All'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Filter by category',
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // Item list
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _firestoreService.getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data.'));
                }

                final items = snapshot.data ?? [];
                final filtered = items.where((item) {
                  final matchesSearch = item.name.toLowerCase().contains(
                    _searchQuery,
                  );
                  final matchesCategory = _selectedCategory == 'All'
                      ? true
                      : item.category.toLowerCase() ==
                            _selectedCategory.toLowerCase();
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No items found.'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        'Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)} • ${item.category}',
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditItemScreen(item: item),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
