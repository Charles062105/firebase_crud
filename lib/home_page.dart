import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'crud_service.dart';

class HomePage extends StatelessWidget {
  final CrudService service = CrudService();
  final AuthService authService = AuthService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    var showFavorites = false;
    return StatefulBuilder(
      builder: (context, setState) => Scaffold(
        backgroundColor: Colors.grey[400],
        appBar: AppBar(
          title: const Text('Quimado'),
          centerTitle: true,
          backgroundColor: Colors.teal,
          actions: [
            IconButton(
              tooltip: showFavorites ? 'Show all items' : 'Show favorites',
              icon: Icon(
                showFavorites ? Icons.favorite : Icons.favorite_border,
                color: Colors.white,
              ),
              onPressed: () => setState(() {
                showFavorites = !showFavorites;
              }),
            ),
            // Added: sign out and return to the registered login route.
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                await authService.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add, color: Colors.white),
          onPressed: () => openAddDialog(context),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: service.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs.where((item) {
              return !showFavorites || _isFavorite(item);
            }).toList();

            if (docs.isEmpty) {
              return const Center(
                child: Text("No items found.", style: TextStyle(fontSize: 18)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                var item = docs[index];
                final isFavorite = _isFavorite(item);

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: const Color(0xFFF7F0FA),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Quantity: ${item['quantity']}",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () =>
                              service.setFavorite(item.id, !isFavorite),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => openEditDialog(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => confirmDelete(context, item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  bool _isFavorite(DocumentSnapshot item) {
    final data = item.data();
    return data is Map && data['favorite'] == true;
  }

  void confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                service.deleteItem(id);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add'),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim());
              if (name.isNotEmpty && quantity != null && quantity > 0) {
                service.addItem(name, quantity);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  void openEditDialog(BuildContext context, DocumentSnapshot item) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Update'),
            onPressed: () {
              final name = nameCtrl.text.trim();
              final quantity = int.tryParse(qtyCtrl.text.trim());
              if (name.isNotEmpty && quantity != null && quantity > 0) {
                service.updateItem(item.id, name, quantity);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}
