import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipantry/providers/auth_provider.dart';
import 'package:unipantry/providers/food_provider.dart'; // For firestoreProvider
import 'package:uuid/uuid.dart';

// 1. Stream of User Models (The Members)
final householdMembersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final householdId = ref.watch(householdIdProvider);
  final firestore = ref.watch(firestoreProvider);

  if (householdId == null) return Stream.value([]);

  // Query the 'users' collection for anyone with this householdId
  return firestore
      .collection('users')
      .where('householdId', isEqualTo: householdId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

// 2. Stream of Household Data (To find out who the Owner is)
final householdDataProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final householdId = ref.watch(householdIdProvider);
  final firestore = ref.watch(firestoreProvider);

  if (householdId == null) return Stream.value(null);

  return firestore
      .collection('households')
      .doc(householdId)
      .snapshots()
      .map((doc) => doc.data());
});

// 3. Actions Provider
final householdActionsProvider = Provider((ref) {
  return HouseholdActions(
    ref.watch(firestoreProvider),
    ref.watch(householdIdProvider),
  );
});

class HouseholdActions {
  final FirebaseFirestore firestore;
  final String? householdId;

  HouseholdActions(this.firestore, this.householdId);

  // --- Remove Member Logic ---
  Future<void> removeMember(String targetUserId, String targetUserEmail) async {
    if (householdId == null) return;

    final batch = firestore.batch();

    // 1. Remove from Household's 'members' array
    final householdRef = firestore.collection('households').doc(householdId);
    batch.update(householdRef, {
      'members': FieldValue.arrayRemove([targetUserEmail])
    });

    // 2. Kick the user out (Give them a brand new, empty household ID)
    // If we set it to null, the app might crash depending on your checks.
    // Creating a new ID is safer; they effectively start over alone.
    final newHouseholdId = const Uuid().v4();
    final userRef = firestore.collection('users').doc(targetUserId);
    
    batch.update(userRef, {
      'householdId': newHouseholdId
    });

    // 3. Create the new household doc for them so they aren't homeless
    final newHouseholdRef = firestore.collection('households').doc(newHouseholdId);
    batch.set(newHouseholdRef, {
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': targetUserId,
      'members': [targetUserEmail],
    });

    await batch.commit();
  }
}