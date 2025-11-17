// lib/providers/auth_provider.dart
import 'package:unipantry/providers/food_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. A provider for the FirebaseAuth instance
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// 2. A stream provider to watch the user's auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// 3. A provider for our AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

// 4. A provider for the current user's household ID
// This is THE KEY to the household feature
final householdIdProvider = StateProvider<String?>((ref) {
  // We will get this from the user's document
  return null;
});

// This is the class that does the work
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  AuthService(this._firebaseAuth, this._firestore);

  Future<void> signInAnonymouslyAndCreateHousehold() async {
    try {
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;

      if (user != null) {
        // Check if the user document already exists
        final userDoc = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          // This is a new user, create a new household
          final newHouseholdId = const Uuid().v4();

          // Create household document
          await _firestore.collection('households').doc(newHouseholdId).set({
            'createdAt': FieldValue.serverTimestamp(),
            'ownerId': user.uid,
          });

          // Create user document and link to household
          await userDoc.set({
            'uid': user.uid,
            'householdId': newHouseholdId,
          });
        }
      }
    } catch (e) {
      // Handle error
      print(e);
    }
  }

  // You would add other auth methods here (signOut, etc.)
}