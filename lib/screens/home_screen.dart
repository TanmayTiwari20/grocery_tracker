import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../db/grocery_database.dart';
import '../models/grocery_item.dart';
import '../services/theme_provider.dart';
import '../services/notification_service.dart';
import 'add_item_screen.dart';
import 'edit_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<GroceryItem>> _items;
  bool _sortByExpiry = true;

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _checkExpiringGroceries(); // Manual trigger on launch
  }

  void _refreshItems() {
    _items = GroceryDatabase.instance.getAllItems(sortByExpiry: _sortByExpiry);
  }

  void _toggleSort() {
    setState(() {
      _sortByExpiry = !_sortByExpiry;
      _refreshItems();
    });
  }

  Future<void> _checkExpiringGroceries() async {
    final db = GroceryDatabase.instance;
    final items = await db.getAllItems();

    final now = DateTime.now();
    final expiring = items.where((item) {
      final daysLeft = item.expiryDate.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= 1;
    }).toList();

    if (expiring.isNotEmpty) {
      await NotificationService.showNotification(
        'Items expiring soon',
        expiring.map((e) => e.name).join(', '),
      );
    }

    for (var item in items) {
      final expiredDays = now.difference(item.expiryDate).inDays;
      if (expiredDays > 2) {
        await db.delete(item.id!);
      }
    }
  }

  String _getStatus(DateTime expiryDate) {
    final now = DateTime.now();
    final diff = expiryDate.difference(now).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires Today';
    if (diff <= 2) return 'Expiring Soon';
    return 'Fresh';
  }

  Color _getColor(String status) {
    switch (status) {
      case 'Expired':
        return Colors.red.shade300;
      case 'Expires Today':
        return Colors.orange;
      case 'Expiring Soon':
        return Colors.yellow.shade700;
      default:
        return Colors.green.shade400;
    }
  }

  Widget _buildCard(GroceryItem item) {
    final status = _getStatus(item.expiryDate);
    return Dismissible(
      key: Key(item.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      onDismissed: (_) async {
        await GroceryDatabase.instance.delete(item.id!);
        if (mounted) {
          setState(() {
            // Remove the item directly from the local list
            _items = _items.then(
              (all) => all.where((i) => i.id != item.id).toList(),
            );
          });
        }
      },
      child: Card(
        color: _getColor(status),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          title: Text(item.name),
          subtitle: Text(
            'Qty: ${item.quantity}\nExpires: ${DateFormat.yMMMd().format(item.expiryDate)}',
          ),
          trailing: Text(status),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditItemScreen(item: item)),
            );
            if (mounted) setState(_refreshItems);
          },
        ),
      ),
    );
  }

  List<Widget> _buildSection(String title, List<GroceryItem> sectionItems) {
    if (sectionItems.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      ...sectionItems.map((item) => _buildCard(item)).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tanmay Ki Groceries'),
        actions: [
          Switch(
            value: Provider.of<ThemeProvider>(context).isDarkMode,
            onChanged: (_) => Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).toggleTheme(),
          ),
          IconButton(
            icon: Icon(_sortByExpiry ? Icons.schedule : Icons.add),
            tooltip: "Toggle sort",
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: FutureBuilder<List<GroceryItem>>(
        future: _items,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No groceries added.'));
          }

          List<GroceryItem> expired = [];
          List<GroceryItem> today = [];
          List<GroceryItem> soon = [];
          List<GroceryItem> fresh = [];

          for (var item in items) {
            final diff = item.expiryDate.difference(DateTime.now()).inDays;
            if (diff < 0)
              expired.add(item);
            else if (diff == 0)
              today.add(item);
            else if (diff <= 2)
              soon.add(item);
            else
              fresh.add(item);
          }

          return ListView(
            children: [
              ..._buildSection("Expired", expired),
              ..._buildSection("Expires Today", today),
              ..._buildSection("Expiring Soon", soon),
              ..._buildSection("Fresh", fresh),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (mounted) setState(_refreshItems);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
