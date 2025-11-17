// lib/providers/food_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unipantry/models/food_item.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/screens/home_screen.dart'; // For the filter

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
// This is what the HomeScreen watches. It automatically updates!
final foodItemsStreamProvider =
    StreamProvider.family<List<FoodItem>, FoodFilter>((ref, filter) {
  final householdId = ref.watch(householdIdProvider);

  if (householdId == null) {
    // This is a failsafe. We must have a householdId
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;
    if (user != null) {
      // Fetch the user doc to find the householdId
      final userDoc = ref
          .watch(firestoreProvider)
          .collection('users')
          .doc(user.uid)
          .get();
      userDoc.then((doc) {
        if (doc.exists) {
          // Update the StateProvider, which will trigger this to re-run
          ref.read(householdIdProvider.notifier).state = doc.data()?['householdId'];
        }
      });
    }
    // Return an empty stream while we figure this out
    return Stream.value([]);
  }

  // We have a householdId, so return the real stream
  return ref.watch(foodServiceProvider).getFoodItemsStream(filter);
});

// This is the class that does the work
class FirestoreService {
  final FirebaseFirestore firestore;
  final String? householdId;

  FirestoreService({required this.firestore, required this.householdId});

  // Get the path to the items subcollection
  CollectionReference get _itemsCollection =>
      firestore.collection('households').doc(householdId).collection('items');

  // Add a new food item
  Future<void> addFoodItem(FoodItem item) async {
    if (householdId == null) return;
    await _itemsCollection.add(item.toJson());
  }

  // Get a stream of food items based on the filter
  Stream<List<FoodItem>> getFoodItemsStream(FoodFilter filter) {
    if (householdId == null) return Stream.value([]);

    Query query = _itemsCollection;
    final now = DateTime.now();

    // This is the "NoWaste" filter logic
    switch (filter) {
      case FoodFilter.expiringSoon:
        final threeDaysFromNow = now.add(const Duration(days: 3));
        query = query
            .where('expiryDate', isGreaterThanOrEqualTo: now)
            .where('expiryDate', isLessThanOrEqualTo: threeDaysFromNow)
            .orderBy('expiryDate');
        break;
      case FoodFilter.expired:
        query = query
            .where('expiryDate', isLessThan: now)
            .orderBy('expiryDate');
        break;
      case FoodFilter.all:
      // ignore: unreachable_switch_default
      default:
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