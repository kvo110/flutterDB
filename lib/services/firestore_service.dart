import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';

// Centralized Firestore logic for CRUD operations
class FirestoreService {
  final CollectionReference _itemsCollection = FirebaseFirestore.instance
      .collection('items');

  // Add a new item
  Future<void> addItem(Item item) async {
    await _itemsCollection.add(item.toMap());
  }

  // Stream all items in real time
  Stream<List<Item>> getItemsStream() {
    return _itemsCollection
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

  // Update an existing item
  Future<void> updateItem(Item item) async {
    if (item.id == null) return;
    await _itemsCollection.doc(item.id).update(item.toMap());
  }

  // Delete an item by its document ID
  Future<void> deleteItem(String id) async {
    await _itemsCollection.doc(id).delete();
  }
}
