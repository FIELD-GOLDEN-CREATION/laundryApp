import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/saved_card.dart';
import '../state/saved_cards_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'card_brand_tag.dart';
import 'remote_image.dart';

String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

/// The "link a card" bottom-sheet form shared by Profile's "Saved cards"
/// section and Checkout's card picker. [onSaved] lets a caller (Checkout)
/// auto-select the card once it's linked.
void showLinkCardSheet(BuildContext context, WidgetRef ref, {ValueChanged<SavedCard>? onSaved}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _LinkCardSheet(ref: ref, onSaved: onSaved),
  );
}

class _LinkCardSheet extends StatefulWidget {
  const _LinkCardSheet({required this.ref, required this.onSaved});

  final WidgetRef ref;
  final ValueChanged<SavedCard>? onSaved;

  @override
  State<_LinkCardSheet> createState() => _LinkCardSheetState();
}

class _LinkCardSheetState extends State<_LinkCardSheet> {
  final _nameCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  CardBrand _brand = CardBrand.bank;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _onNumberChanged(String v) => setState(() => _brand = detectCardBrand(_digitsOnly(v)));

  void _save() {
    final name = _nameCtrl.text.trim();
    final digits = _digitsOnly(_numberCtrl.text);
    final expiry = _expiryCtrl.text.trim();
    final cvv = _cvvCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Enter the name on the card.');
      return;
    }
    if (digits.length < 12 || digits.length > 19) {
      setState(() => _error = 'Enter a valid card number.');
      return;
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(expiry)) {
      setState(() => _error = 'Enter expiry as MM/YY.');
      return;
    }
    if (cvv.length < 3 || cvv.length > 4) {
      setState(() => _error = 'Enter a valid CVV.');
      return;
    }

    final card = SavedCard(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      holderName: name,
      last4: digits.substring(digits.length - 4),
      expiry: expiry,
      brand: detectCardBrand(digits),
    );
    widget.ref.read(savedCardsProvider.notifier).add(card);
    Navigator.of(context).pop();
    widget.onSaved?.call(card);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: const Color(0xFFDED8CA), borderRadius: BorderRadius.circular(99)),
              ),
            ),
            Text('Link a card', style: AppText.serif(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              'Saved to your account for faster checkout',
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            _CardVisual(brand: _brand),
            const SizedBox(height: 16),
            _Field(label: 'Name on card', hint: 'Amara Reed', controller: _nameCtrl),
            const SizedBox(height: 12),
            _Field(
              label: 'Card number',
              hint: '4242 4242 4242 4242',
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              onChanged: _onNumberChanged,
              trailing: _numberCtrl.text.trim().isEmpty ? null : CardBrandTag(brand: _brand),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    label: 'Expiry',
                    hint: 'MM/YY',
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    label: 'CVV',
                    hint: '123',
                    controller: _cvvCtrl,
                    obscure: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.creamDark, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Text(
                          'Cancel',
                          style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 7,
                  child: Material(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: _save,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: Text(
                          'Save card',
                          style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.cream),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  const _CardVisual({required this.brand});

  final CardBrand brand;

  @override
  Widget build(BuildContext context) {
    final brandText = brandLabel(brand).toUpperCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 116,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const RemoteImage(url: kCardPhotoUrl, fallback: 'Card', placeholder: ColoredBox(color: Color(0xFF2C3E50))),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      brandText,
                      style: AppText.sans(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.6),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '•••• •••• •••• ••••',
                    style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.trailing,
    this.onChanged,
    this.obscure = false,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.eyebrow()),
        const SizedBox(height: 7),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.creamDark),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ],
    );
  }
}
