import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/profile_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/placeholder_image.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final name = TextEditingController(text: ref.read(profileProvider).name);
  late final phone = TextEditingController(text: ref.read(profileProvider).phone);
  String photoLabel = 'You';
  @override
  void dispose() { name.dispose(); phone.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Edit profile', style: AppText.serif(fontSize: 24)), backgroundColor: AppColors.cream, foregroundColor: AppColors.slate),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: Stack(alignment: Alignment.bottomRight, children: [SizedBox(width: 96, height: 96, child: PlaceholderImage(label: photoLabel, circle: true)), FloatingActionButton.small(backgroundColor: AppColors.teal, onPressed: () => setState(() => photoLabel = photoLabel == 'You' ? 'New photo' : 'You'), child: const Icon(Icons.camera_alt_outlined, color: AppColors.cream))])),
      const SizedBox(height: 25),
      _Field(label: 'Full name', controller: name),
      _Field(label: 'Phone number', controller: phone, keyboardType: TextInputType.phone),
      const SizedBox(height: 14),
      FilledButton(onPressed: () { if (name.text.trim().isEmpty || phone.text.trim().isEmpty) return; ref.read(profileProvider.notifier).updateDetails(name: name.text.trim(), phone: phone.text.trim(), photoLabel: photoLabel); Navigator.pop(context); }, style: FilledButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 16)), child: Text('Save changes', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream))),
    ]),
  );
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.controller, this.keyboardType});
  final String label; final TextEditingController controller; final TextInputType? keyboardType;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.creamDark)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.creamDark)),
      ),
    ),
  );
}
