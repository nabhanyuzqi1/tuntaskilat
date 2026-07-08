import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  try {
    final docs = await FirebaseFirestore.instance.collection('orders').where('kruIds', arrayContains: 'someId').get();
    print('SUCCESS: ${docs.docs.length}');
  } catch (e) {
    print('ERROR: $e');
  }
}
