import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:unipantry/providers/food_provider.dart'; // Needed for firestoreProvider

// 1. Provider for FirebaseAuth Instance
final firebaseAuthProvider =
    Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// 2. Stream provider to watch the user's auth state (Logged in / Logged out)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

// 3. Provider for AuthService class
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
    ref, 
  );
});

// 4. Household Notifier (Manages the Household ID state)
class HouseholdNotifier extends Notifier<String?> {
  @override
  String? build() {
    return null; // Initial state
  }

  // Method to update state from outside
  void setHouseholdId(String? id) {
    state = id;
  }
}

final householdIdProvider = NotifierProvider<HouseholdNotifier, String?>(() {
  return HouseholdNotifier();
});

// --- THE SERVICE CLASS ---
class AuthService {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final Ref _ref;

  AuthService(this._firebaseAuth, this._firestore, this._ref);

  // --- 1. SIGN UP (Create Account + New Household) ---
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      // A. Create Auth User
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        // B. Generate new Household ID
        final newHouseholdId = const Uuid().v4();

        // C. Create Household Document
        await _firestore.collection('households').doc(newHouseholdId).set({
          'createdAt': FieldValue.serverTimestamp(),
          'ownerId': user.uid,
          'members': [email], // Track who is in it
        });

        // D. Create User Document
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'householdId': newHouseholdId,
          'displayName': '', // Empty initially
          'photoUrl': null,
        });

        // E. Update Local State
        _ref.read(householdIdProvider.notifier).setHouseholdId(newHouseholdId);
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- 2. SIGN IN (Login + Fetch Household) ---
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // A. Sign In
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        // B. Fetch User Doc to get Household ID
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final householdId = userDoc.data()?['householdId'];
          // C. Update Local State
          _ref.read(householdIdProvider.notifier).setHouseholdId(householdId);
        }
      }
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- 3. JOIN HOUSEHOLD (Switch Pantry) ---
  Future<void> joinHousehold(String targetHouseholdId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Check if household exists
    final houseDoc = await _firestore.collection('households').doc(targetHouseholdId).get();
    if (!houseDoc.exists) throw Exception('Invalid Household ID');

    // Update User Doc
    await _firestore.collection('users').doc(user.uid).update({
      'householdId': targetHouseholdId,
    });

    // Update Household Member List (Optional but good practice)
    await _firestore.collection('households').doc(targetHouseholdId).update({
      'members': FieldValue.arrayUnion([user.email])
    });

    // Update State
    _ref.read(householdIdProvider.notifier).setHouseholdId(targetHouseholdId);
  }

  // --- 4. UPDATE PROFILE (Name & Photo) ---
  Future<void> updateUserProfile({String? name, String? photoUrl}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    // A. Update Auth Profile (The standard Firebase User object)
    if (name != null) await user.updateDisplayName(name);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);

    // B. Update Firestore User Doc (So other household members can see details later)
    final data = <String, dynamic>{};
    if (name != null) data['displayName'] = name;
    if (photoUrl != null) data['photoUrl'] = photoUrl;

    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(user.uid).update(data);
    }
    
    // C. Force reload to refresh UI immediately
    await user.reload();
  }

  // --- 5. UPLOAD IMAGE TO STORAGE ---
  Future<String> uploadProfileImage(File imageFile) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Create a reference: users/{uid}/profile.jpg
    // Note: This overwrites the old image every time, which saves space.
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(user.uid)
        .child('profile.jpg');

    // Upload
    await storageRef.putFile(imageFile);

    // Get the public URL
    return await storageRef.getDownloadURL();
  }

  // --- 6. SIGN OUT ---
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _ref.read(householdIdProvider.notifier).setHouseholdId(null);
  }

  // --- ERROR HANDLING HELPER ---
  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use': return 'This email is already registered.';
        case 'invalid-email': return 'Invalid email address.';
        case 'weak-password': return 'Password is too weak.';
        case 'user-not-found': return 'No user found with this email.';
        case 'wrong-password': return 'Incorrect password.';
        case 'channel-error': return 'Please enter both email and password.';
        default: return e.message ?? 'Authentication failed.';
      }
    }
    return e.toString();
  }
}