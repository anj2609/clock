import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alarm.dart';
import '../utils/constants.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    } catch (e) {
      throw Exception(AppConstants.errorUnknown);
    }
  }

  Future<UserCredential> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    } catch (e) {
      throw Exception(AppConstants.errorUnknown);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception(AppConstants.errorUnknown);
    }
  }

  CollectionReference<Map<String, dynamic>> _alarmsCollection(String uid) {
    return _firestore
        .collection(AppConstants.firestoreUsersCollection)
        .doc(uid)
        .collection(AppConstants.firestoreAlarmsCollection);
  }

  Stream<List<Alarm>> alarmsStream(String uid) {
    return _alarmsCollection(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Alarm.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addAlarm(String uid, Alarm alarm) async {
    try {
      await _alarmsCollection(uid).doc(alarm.id).set(alarm.toFirestore());
    } catch (e) {
      throw Exception(AppConstants.errorSavingAlarm);
    }
  }

  Future<void> updateAlarm(String uid, Alarm alarm) async {
    try {
      await _alarmsCollection(uid).doc(alarm.id).update(alarm.toFirestore());
    } catch (e) {
      throw Exception(AppConstants.errorSavingAlarm);
    }
  }

  Future<void> deleteAlarm(String uid, String alarmId) async {
    try {
      await _alarmsCollection(uid).doc(alarmId).delete();
    } catch (e) {
      throw Exception(AppConstants.errorDeletingAlarm);
    }
  }

  Future<List<Alarm>> fetchAllAlarms(String uid) async {
    try {
      final snapshot = await _alarmsCollection(uid).get();
      return snapshot.docs.map((doc) {
        return Alarm.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception(AppConstants.errorLoadingAlarms);
    }
  }

  Future<void> setThemePreference(String uid, bool isDarkMode) async {
    try {
      await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(uid)
          .collection(AppConstants.firestoreSettingsCollection)
          .doc(AppConstants.firestoreThemeDocument)
          .set({AppConstants.isDarkModeKey: isDarkMode});
    } catch (_) {}
  }

  Future<bool> getThemePreference(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.firestoreUsersCollection)
          .doc(uid)
          .collection(AppConstants.firestoreSettingsCollection)
          .doc(AppConstants.firestoreThemeDocument)
          .get();
      if (doc.exists && doc.data() != null) {
        return doc.data()![AppConstants.isDarkModeKey] as bool? ?? false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return AppConstants.errorInvalidEmail;
      case 'wrong-password':
        return AppConstants.errorWrongPassword;
      case 'user-not-found':
        return AppConstants.errorUserNotFound;
      case 'weak-password':
        return AppConstants.errorWeakPassword;
      case 'email-already-in-use':
        return AppConstants.errorEmailAlreadyInUse;
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return AppConstants.errorNetworkRequest;
      default:
        return AppConstants.errorUnknown;
    }
  }
}
