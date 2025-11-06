import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import '../models/category.dart';

class FirestoreService {
  // Collection for items
  final CollectionReference _itemsRef = FirebaseFirestore.instance.collection(
    'items',
  );

  // Collection for categories
  final CollectionReference _categoriesRef = FirebaseFirestore.instance
      .collection('categories');

  // -------------------- ITEMS --------------------

  Future<void> addItem(Item item) async {
    await _itemsRef.add(item.toMap());
  }

  Stream<List<Item>> getItemsStream() {
    return _itemsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    Item.fromMap(doc.id, doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<void> updateItem(Item item) async {
    if (item.id == null) return;
    await _itemsRef.doc(item.id).update(item.toMap());
  }

  Future<void> deleteItem(String id) async {
    await _itemsRef.doc(id).delete();
  }

  // -------------------- CATEGORIES --------------------

  Stream<List<Category>> getCategoriesStream() {
    return _categoriesRef.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                Category.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Future<void> addCategory(String name) async {
    // prevent duplicates
    final existing = await _categoriesRef
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _categoriesRef.add({'name': name});
    }
  }
}
