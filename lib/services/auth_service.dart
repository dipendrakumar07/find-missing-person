import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _isGuest = false;
        _guestName = null;
        _guestEmail = null;
        _guestUid = null;
        _loadCustomProfile(user.uid);
      } else {
        _cachedCustomPhotoUrl = null;
      }
      notifyListeners();
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '1031694875467-n71pcks0lbstqubeaq8oj3tv4gvrtdia.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  bool _isGuest = false;
  String? _guestName;
  String? _guestEmail;
  String? _guestUid;
  String? _cachedCustomPhotoUrl;

  Future<void> _loadCustomProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get().timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final customPhoto = (data['photoURL'] ?? '').toString().trim();
        if (customPhoto.isNotEmpty) {
          _cachedCustomPhotoUrl = customPhoto;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null || _isGuest;

  bool get isGuest => _isGuest;

  String get userDisplayName {
    if (_auth.currentUser?.displayName != null &&
        _auth.currentUser!.displayName!.trim().isNotEmpty) {
      return _auth.currentUser!.displayName!.trim();
    }
    if (_guestName != null && _guestName!.trim().isNotEmpty) {
      return _guestName!.trim();
    }
    if (_auth.currentUser?.email != null) {
      return _auth.currentUser!.email!.split('@').first;
    }
    return 'Citizen';
  }

  String get userEmail {
    return _auth.currentUser?.email ?? _guestEmail ?? '';
  }

  String get userId {
    return _auth.currentUser?.uid ?? _guestUid ?? '';
  }

  String? get userPhotoUrl => _cachedCustomPhotoUrl ?? _auth.currentUser?.photoURL;

  String? get userPhone => _auth.currentUser?.phoneNumber;

  /// Fetch user profile details from Firestore with fallback to Firebase Auth
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'displayName': userDisplayName,
        'email': userEmail,
        'phoneNumber': '',
        'photoURL': '',
        'bio': 'Community Safety Volunteer',
        'city': '',
        'role': 'user',
      };
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 4));
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final customPhoto = (data['photoURL'] ?? user.photoURL ?? '').toString().trim();
        if (customPhoto.isNotEmpty) {
          _cachedCustomPhotoUrl = customPhoto;
        }
        return {
          'displayName': (data['displayName'] ?? user.displayName ?? '').toString().trim().isNotEmpty
              ? (data['displayName'] ?? user.displayName).toString()
              : userDisplayName,
          'email': (data['email'] ?? user.email ?? '').toString(),
          'phoneNumber': (data['phoneNumber'] ?? user.phoneNumber ?? '').toString(),
          'photoURL': customPhoto,
          'bio': (data['bio'] ?? 'Community Safety Volunteer · Helping locate lost loved ones').toString(),
          'city': (data['city'] ?? '').toString(),
          'role': (data['role'] ?? 'user').toString(),
          'hideEmail': data['hideEmail'] ?? true,
          'showPhone': data['showPhone'] ?? true,
          'showCity': data['showCity'] ?? true,
        };
      }
    } catch (e) {
      debugPrint('Error getting user profile from Firestore: $e');
    }

    return {
      'displayName': userDisplayName,
      'email': user.email ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'photoURL': user.photoURL ?? '',
      'bio': 'Community Safety Volunteer · Helping locate lost loved ones',
      'city': '',
      'role': 'user',
      'hideEmail': true,
      'showPhone': true,
      'showCity': true,
    };
  }

  /// Update user profile both in FirebaseAuth and Cloud Firestore
  Future<void> updateUserProfile({
    required String displayName,
    String? phoneNumber,
    String? photoURL,
    String? bio,
    String? city,
    bool? hideEmail,
    bool? showPhone,
    bool? showCity,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Update Firebase Auth user
    try {
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim()).timeout(const Duration(seconds: 4));
      }
      if (photoURL != null && photoURL.trim().isNotEmpty) {
        await user.updatePhotoURL(photoURL.trim()).timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('FirebaseAuth update notice: $e');
    }

    // 2. Update Cloud Firestore user document
    try {
      final updateData = <String, dynamic>{
        'displayName': displayName.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber.trim();
      if (photoURL != null && photoURL.trim().isNotEmpty) {
        final cleanPhoto = photoURL.trim();
        updateData['photoURL'] = cleanPhoto;
        updateData['hasCustomPhoto'] = true;
        _cachedCustomPhotoUrl = cleanPhoto;
      }
      if (bio != null) updateData['bio'] = bio.trim();
      if (city != null) updateData['city'] = city.trim();
      if (hideEmail != null) updateData['hideEmail'] = hideEmail;
      if (showPhone != null) updateData['showPhone'] = showPhone;
      if (showCity != null) updateData['showCity'] = showCity;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(updateData, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Firestore update notice: $e');
    }

    notifyListeners();
  }

  /// Check if the currently logged-in user is an admin.
  bool get isCurrentAdmin {
    if (_isGuest) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    final email = (user.email ?? '').toLowerCase().trim();
    final displayName = (user.displayName ?? '').toLowerCase().trim();

    if (email.contains('admin') ||
        email == 'admin@findmissingperson.org' ||
        email == 'admin@gmail.com' ||
        displayName.contains('admin') ||
        displayName.contains('moderator') ||
        displayName.contains('police')) {
      return true;
    }

    return false;
  }

  /// Async check for admin status with Firestore role validation
  Future<bool> checkIsAdmin() async {
    if (_isGuest) return false;
    final user = _auth.currentUser;
    if (user == null) return false;

    if (isCurrentAdmin) return true;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final role = (data['role'] ?? '').toString().toLowerCase();
          final isAdminFlag = data['isAdmin'] == true;
          return role == 'admin' || role == 'moderator' || isAdminFlag;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Sign In with Google (Real Native on Android / Popup on Web)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth
            .signInWithPopup(googleProvider)
            .timeout(const Duration(seconds: 25));
      } else {
        // Native Android Google Sign-In dialog
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
          const Duration(seconds: 40),
          onTimeout: () => throw 'Google Sign-In timed out. Please try again.',
        );
        if (googleUser == null) {
          // User backed out / canceled the dialog
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw 'Google authentication token timed out. Please try again.',
        );
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth
            .signInWithCredential(credential)
            .timeout(const Duration(seconds: 20), onTimeout: () {
              throw 'Firebase authentication timed out. Please check your internet connection.';
            });
      }

      if (userCredential.user != null) {
        _isGuest = false;
        notifyListeners();
        // Asynchronously save to Firestore in background without blocking login
        _saveUserToFirestore(userCredential.user!, 'google');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      throw 'Google Sign-In failed: ${e.toString()}';
    }
  }

  /// Sign in with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw 'Login timed out. Please check your internet connection.';
          });

      _isGuest = false;
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Login failed: ${e.toString()}';
    }
  }

  /// Register / Sign Up with Email and Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
    String? phoneNumber,
    String role = 'user',
  }) async {
    try {
      final credential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          )
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw 'Registration timed out. Please check your internet connection.';
          });

      if (displayName != null && displayName.trim().isNotEmpty) {
        try {
          await credential.user
              ?.updateDisplayName(displayName.trim())
              .timeout(const Duration(seconds: 4));
        } catch (_) {}
      }

      final isEmailAdmin = email.toLowerCase().contains('admin');
      final assignedRole = isEmailAdmin ? 'admin' : role;

      // Unblock and notify immediately! User is authenticated!
      _isGuest = false;
      notifyListeners();

      // Save user profile asynchronously to Firestore with timeout
      if (credential.user != null) {
        _saveUserToFirestore(
          credential.user!,
          'password',
          extraData: {
            'displayName': displayName?.trim() ?? '',
            'phoneNumber': phoneNumber?.trim() ?? '',
            'role': assignedRole,
            'isAdmin': assignedRole == 'admin',
          },
        );
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Registration failed: ${e.toString()}';
    }
  }

  /// Helper to save user document to Firestore with safe timeout
  Future<void> _saveUserToFirestore(
    User user,
    String provider, {
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      String effectivePhotoUrl = user.photoURL ?? '';
      bool hasCustomPhoto = false;

      // Check if existing document already has a custom profile photo
      try {
        final existingDoc = await docRef.get().timeout(const Duration(seconds: 4));
        if (existingDoc.exists && existingDoc.data() != null) {
          final existingData = existingDoc.data()!;
          final savedPhoto = (existingData['photoURL'] ?? '').toString().trim();
          hasCustomPhoto = existingData['hasCustomPhoto'] as bool? ?? false;

          // If the user previously uploaded a custom photo, preserve it! Do NOT overwrite with Google photo!
          if (hasCustomPhoto || (savedPhoto.isNotEmpty && !savedPhoto.contains('googleusercontent.com'))) {
            effectivePhotoUrl = savedPhoto;
            hasCustomPhoto = true;
          }
        }
      } catch (_) {}

      _cachedCustomPhotoUrl = effectivePhotoUrl.isNotEmpty ? effectivePhotoUrl : null;

      final data = {
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'photoURL': effectivePhotoUrl,
        'hasCustomPhoto': hasCustomPhoto,
        'role': 'user',
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'authProvider': provider,
        ...?extraData,
      };

      await docRef
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('Warning: Could not save user to Firestore: $e');
    }
  }

  /// Guest / Skip login for viewing public posts only
  Future<void> signInAsGuest({String? name, String? email}) async {
    _isGuest = true;
    _guestName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Guest Citizen';
    _guestEmail = email;
    _guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    notifyListeners();
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }
    } catch (_) {}
    _isGuest = false;
    _guestName = null;
    _guestEmail = null;
    _guestUid = null;
    _cachedCustomPhotoUrl = null;
    notifyListeners();
  }

  /// Clean, human-readable error messages for authentication
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials or register.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Please log in.';
      case 'invalid-email':
        return 'The email address format is not valid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      default:
        return e.message ?? 'Authentication error occurred. Please try again.';
    }
  }

  /// Find user account and send password reset email/link.
  /// Strictly checks if account exists first.
  /// If NOT found: returns error and does NOT send anything.
  Future<Map<String, dynamic>> sendPasswordReset({required String emailOrPhone}) async {
    final input = emailOrPhone.trim();
    if (input.isEmpty) {
      return {'success': false, 'message': 'Please enter your email address or mobile number.'};
    }

    final isEmail = input.contains('@');
    String targetEmail = input.toLowerCase();

    // 1. Search in Cloud Firestore 'users' collection
    try {
      QuerySnapshot userSnapshot;
      if (isEmail) {
        userSnapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: targetEmail)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));

        // Fallback check: exact input case
        if (userSnapshot.docs.isEmpty && input != targetEmail) {
          userSnapshot = await _firestore
              .collection('users')
              .where('email', isEqualTo: input)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 5));
        }
      } else {
        // Search by phone number
        final cleanPhone = input.replaceAll(RegExp(r'[^0-9]'), '');
        userSnapshot = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: cleanPhone)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));
      }

      // Check if user was found in Firestore
      if (userSnapshot.docs.isEmpty) {
        // Also check Firebase Auth directly
        if (isEmail) {
          try {
            final methods = await _auth.fetchSignInMethodsForEmail(targetEmail);
            if (methods.isEmpty) {
              return {
                'success': false,
                'message': 'Iss email se koi account nahi mila! Kripya sahi email dalein ya naya account banayein.',
              };
            }
          } catch (e) {
            return {
              'success': false,
              'message': 'Iss email se koi account nahi mila! Kripya sahi email dalein ya naya account banayein.',
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Iss mobile number se koi account nahi mila! Kripya sahi number dalein.',
          };
        }
      }

      // User exists!
      Map<String, dynamic>? userData;
      if (userSnapshot.docs.isNotEmpty) {
        userData = userSnapshot.docs.first.data() as Map<String, dynamic>?;
        if (userData != null && userData['email'] != null && userData['email'].toString().isNotEmpty) {
          targetEmail = userData['email'].toString().trim().toLowerCase();
        }
      }

      // Check if this is a Google Sign-In account
      final provider = userData?['authProvider']?.toString().toLowerCase() ?? '';
      if (provider.contains('google')) {
        return {
          'success': false,
          'isGoogle': true,
          'message': 'Ye account Google Sign-In se register hua hai. Iske liye password reset ki jarurat nahi hai. Aap direct "Continue with Google" button se login kar sakte hain.',
        };
      }

      // 2. Dispatch official Firebase Password Reset link
      await _auth.sendPasswordResetEmail(email: targetEmail).timeout(const Duration(seconds: 10));

      // 3. Dispatch Gmail SMTP notification
      try {
        await EmailService().sendPasswordResetNotification(
          recipientEmail: targetEmail,
          displayName: userData?['displayName'],
        );
      } catch (_) {}

      return {
        'success': true,
        'email': targetEmail,
        'message': 'Password reset link bhej diya gaya hai! Kripya apna email ($targetEmail) check karein aur link par click karke naya password set karein.',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return {
          'success': false,
          'message': 'Iss email se koi account nahi mila! Kripya sahi email dalein ya naya account banayein.',
        };
      } else if (e.code == 'invalid-email') {
        return {
          'success': false,
          'message': 'Kripya sahi format me email address enter karein.',
        };
      }
      return {
        'success': false,
        'message': 'Password reset request failed: ${e.message}',
      };
    } catch (e) {
      debugPrint('Password reset error: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}
