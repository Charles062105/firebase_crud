import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';

class PickedImage {
  final File file;
  final String url;
  PickedImage({required this.file, required this.url});
}

class CrudService {
  final CollectionReference items =
      FirebaseFirestore.instance.collection('items');

  // 1st arg = your Cloud Name, 2nd arg = your UNSIGNED upload preset
  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'sbh0cavx',
    'firebase_crud',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  // Opens the gallery, uploads to Cloudinary, returns local file + hosted URL.
  Future<PickedImage?> pickImageForAddItem() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null; // user cancelled

    final file = File(pickedFile.path);

    final response = await _cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        file.path,
        resourceType: CloudinaryResourceType.Image,
      ),
    );
    return PickedImage(file: file, url: response.secureUrl);
  }

  //CREATE (with image)
  Future<void> addItemWithImage(
      String name, int quantity, String? imageUrl) async {
    await items.add({
      'name': name,
      'quantity': quantity,
      'image_url': imageUrl,
      'favorite': false,
      'createdAt': Timestamp.now(),
    });
  }

  //READ
  Stream<QuerySnapshot> getItems() {
    return items.orderBy('createdAt', descending: true).snapshots();
  }

  //UPDATE
  Future<void> updateItem(String id, String name, int quantity) {
    return items.doc(id).update({
      'name': name,
      'quantity': quantity,
    });
  }

  //FAVORITE
  Future<void> setFavorite(String id, bool isFavorite) {
    return items.doc(id).update({'favorite': isFavorite});
  }

  //DELETE
  Future<void> deleteItem(String id) {
    return items.doc(id).delete();
  }
}