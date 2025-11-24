import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/screens/home_screen.dart'; // For FoodFilter enum

// 1. A provider for the Firestore instance
final firestoreProvider =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// 2. A provider for our FirestoreService
final foodServiceProvider = Provider<FirestoreService>((ref) {
  // We need the householdId to know *which* pantry to use
  final householdId = ref.watch(householdIdProvider);
  return FirestoreService(
    firestore: ref.watch(firestoreProvider),
    householdId: householdId,
  );
});

// 3. A STREAM PROVIDER to get the list of food items
final foodItemsStreamProvider =
    StreamProvider.family<List<FoodItem>, FoodFilter>((ref, filter) {
  final householdId = ref.watch(householdIdProvider);

  if (householdId == null) {
    // Failsafe: Try to recover householdId if it's missing but user is logged in
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    if (user != null) {
      final userDoc = ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .get();
      userDoc.then((doc) {
        if (doc.exists) {
          ref.read(householdIdProvider.notifier).setHouseholdId(doc.data()?['householdId']);
        }
      });
    }
    return Stream.value([]);
  }

  return ref.watch(foodServiceProvider).getFoodItemsStream(filter);
});

// This is the class that does the heavy lifting
class FirestoreService {
  final FirebaseFirestore firestore;
  final String? householdId;

  FirestoreService({required this.firestore, required this.householdId});

  // Get the path to the items subcollection
  CollectionReference get _itemsCollection =>
      firestore.collection('households').doc(householdId).collection('items');

  // --- CREATE ---
  Future<void> addFoodItem(FoodItem item) async {
    if (householdId == null) return;
    await _itemsCollection.add(item.toJson());
  }

  // --- UPDATE (New) ---
  Future<void> updateFoodItem(FoodItem item) async {
    if (householdId == null) return;
    await _itemsCollection.doc(item.id).update(item.toJson());
  }

  // --- DELETE (New) ---
  Future<void> deleteFoodItem(String itemId) async {
    if (householdId == null) return;
    await _itemsCollection.doc(itemId).delete();
  }

  // --- READ / STREAM ---
  Stream<List<FoodItem>> getFoodItemsStream(FoodFilter filter) {
    if (householdId == null) return Stream.value([]);

    Query query = _itemsCollection;
    final now = DateTime.now();
    // Normalize "now" to midnight for accurate day comparison
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case FoodFilter.expiringSoon:
        // Items expiring between today and 3 days from now
        final threeDaysFromNow = today.add(const Duration(days: 3));
        query = query
            .where('expiryDate', isGreaterThanOrEqualTo: today)
            .where('expiryDate', isLessThanOrEqualTo: threeDaysFromNow)
            .orderBy('expiryDate');
        break;
      case FoodFilter.expired:
        // Items strictly before today
        query = query
            .where('expiryDate', isLessThan: today)
            .orderBy('expiryDate');
        break;
      case FoodFilter.all:
        // All items, ordered by expiry date
        query = query.orderBy('expiryDate');
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FoodItem.fromJson(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}