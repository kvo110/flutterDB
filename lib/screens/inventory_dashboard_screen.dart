import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';

class InventoryDashboardScreen extends StatelessWidget {
  const InventoryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Dashboard'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Item>>(
        stream: firestoreService.getItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading dashboard data.'));
          }

          final items = snapshot.data ?? [];

          final totalItems = items.length;
          final totalValue = items.fold<double>(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );
          final avgPrice = items.isNotEmpty ? totalValue / totalItems : 0.0;
          final outOfStock = items.where((item) => item.quantity <= 0).length;
          final lowStock = items
              .where((item) => item.quantity > 0 && item.quantity < 5)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  children: [
                    _buildMetricCard(
                      title: 'Total Items',
                      value: totalItems.toString(),
                      color: Colors.blue.shade400,
                      icon: Icons.inventory_2,
                    ),
                    _buildMetricCard(
                      title: 'Total Value',
                      value: '\$${totalValue.toStringAsFixed(2)}',
                      color: Colors.green.shade400,
                      icon: Icons.attach_money,
                    ),
                    _buildMetricCard(
                      title: 'Average Price',
                      value: '\$${avgPrice.toStringAsFixed(2)}',
                      color: Colors.purple.shade400,
                      icon: Icons.trending_up,
                    ),
                    _buildMetricCard(
                      title: 'Out of Stock',
                      value: outOfStock.toString(),
                      color: Colors.red.shade400,
                      icon: Icons.warning,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),

                const Text(
                  'Low Stock Items (less than 5)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (lowStock == 0)
                  const Text('All good. No low stock items right now.')
                else
                  Column(
                    children: items
                        .where((item) => item.quantity > 0 && item.quantity < 5)
                        .map(
                          (item) => ListTile(
                            leading: const Icon(
                              Icons.inventory,
                              color: Colors.orange,
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              'Qty: ${item.quantity} • \$${item.price.toStringAsFixed(2)}',
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      color: color,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
