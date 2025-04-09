import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../forms/create_form_screen.dart';
import '../forms/form_list_screen.dart';
import '../widgets/app_bar_widget.dart';
import '../helpers/transition_helper.dart';
import 'package:permission_handler/permission_handler.dart'; // Import nécessaire pour gérer les permissions

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/auth');
  }

  void _requestCameraPermission(BuildContext context) async {
    // Demande la permission d'accéder à la caméra
    PermissionStatus status = await Permission.camera.request();

    if (status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission granted.')));
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission denied.')));
    } else if (status.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permission permanently denied.')));
    }
  }

  void _openCreateForm(BuildContext context) {
    navigateWithSlide(
      context,
      CreateFormScreen(
        onFormCreated: (title, fields) async {
          final userId = FirebaseAuth.instance.currentUser!.uid;
          await FirebaseFirestore.instance.collection('users').doc(userId).collection('forms').add({
            'title': title,
            'fields': fields.map((f) => f.toMap()).toList(),
            'createdAt': Timestamp.now(),
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Form created successfully"),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(actions: [IconButton(onPressed: () => _signOut(context), icon: const Icon(Icons.logout))]),
      body: const FormListScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(context),
        icon: const Icon(Icons.add),
        label: const Text("Create Form"),
      ),
    );
  }
}
