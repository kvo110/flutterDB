import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';
import 'add_edit_item_screen.dart';
import 'inventory_dashboard_screen.dart';

// This is the main screen that lists all items in your Firestore inventory.
class InventoryHomePage extends StatefulWidget {
  final String title;
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode; // <-- this was missing before

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
          // Light/Dark mode toggle icon
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          // Dashboard shortcut button
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'Dashboard',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InventoryDashboardScreen()),
              );
            },
          ),
        ],
      ),

      // --- MAIN BODY ---
      body: Column(
        children: [
          // Search field for filtering items by name
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by item name...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Dropdown for category filtering
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Categories')),
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(
                  value: 'Electronics',
                  child: Text('Electronics'),
                ),
                DropdownMenuItem(value: 'Clothing', child: Text('Clothing')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Filter by category',
              ),
            ),
          ),
          const SizedBox(height: 6),

          // StreamBuilder to automatically refresh items from Firestore
          Expanded(
            child: StreamBuilder<List<Item>>(
              stream: _firestoreService.getItemsStream(),
              builder: (context, snapshot) {
                // Loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error handling
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data.'));
                }

                final items = snapshot.data ?? [];

                // Apply filters for search and category
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

                // Handle empty results
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No items found. Try adding one!'),
                  );
                }

                // Display filtered list of items
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
                        // Go to Edit screen when an item is tapped
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

      // Floating button for adding new items
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
