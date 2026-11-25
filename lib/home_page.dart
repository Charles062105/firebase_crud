import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'crud_service.dart';
import 'login_page.dart';

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
            // Sign out and return to the login page.
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                final shouldLogOut = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('Log out'),
                    content: Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text('Log out'),
                      ),
                    ],
                  ),
                );
                if (shouldLogOut != true || !context.mounted) return;

                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
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

                // CLOUDINARY: read the whole document as a Map, then grab image_url
                final data = item.data() as Map<String, dynamic>;
                final imageUrl = data['image_url'];

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
                    // CLOUDINARY: show the uploaded image (if the item has one)
                    leading: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          )
                        : null,
                    title: Text(
                      data['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Quantity: ${data['quantity'] ?? 0}",
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
            // CLOUDINARY deck addition: cancel button
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void openAddDialog(BuildContext context) {
    nameCtrl.clear();
    qtyCtrl.clear();

    // CLOUDINARY: hold the picked image file and its uploaded URL
    File? selectedImageFile;
    String? selectedImageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
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
              const SizedBox(height: 10),
              if (selectedImageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedImageFile!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(isUploading ? 'Uploading...' : 'Upload Image'),
                onPressed: isUploading
                    ? null
                    : () async {
                        setState(() => isUploading = true);
                        try {
                          // picks from gallery + uploads to Cloudinary
                          final picked = await service.pickImageForAddItem();
                          if (picked != null) {
                            setState(() {
                              selectedImageFile = picked.file;
                              selectedImageUrl = picked.url;
                            });
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Upload failed: $e')),
                            );
                          }
                        } finally {
                          setState(() => isUploading = false);
                        }
                      },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isUploading
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      final quantity = int.tryParse(qtyCtrl.text.trim());
                      if (name.isNotEmpty && quantity != null && quantity > 0) {
                        // CLOUDINARY: save the image URL along with the item
                        await service.addItemWithImage(
                          name,
                          quantity,
                          selectedImageUrl,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      }
                    },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Edit UI is unchanged (image is not editable here).
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