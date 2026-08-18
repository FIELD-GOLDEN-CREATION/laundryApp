import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../models/mobile_money_provider.dart';
import '../models/vendor_payment_method.dart';
import '../state/vendor_payment_methods_state.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'mobile_money_logo.dart';

String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

Widget _sheetHandle() => Center(
  child: Container(
    width: 44,
    height: 5,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(99)),
  ),
);

/// First step of "+ Add payment method": lets the vendor pick which kind of
/// payout method to add, then hands off to [showVendorPaymentMethodForm] for
/// that kind's details. Mirrors the two-step "pick a type, then fill in
/// details" flow used by Checkout's payment picker.
void showVendorPaymentMethodPicker(BuildContext context, WidgetRef ref) {
  final hasCashOnDelivery = ref
      .read(vendorPaymentMethodsProvider)
      .any((m) => m.kind == VendorPaymentMethodKind.cashOnDelivery);

  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.cream,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            Text('Add payment method', style: AppText.serif(fontSize: 22)),
            const SizedBox(height: 3),
            Text(
              'Choose how you want to receive payouts',
              style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            _KindTile(
              icon: Icons.phone_android_rounded,
              label: 'Mobile Money',
              sub: 'M-Pesa, Airtel Money, Mixx by Yas and more',
              onTap: () {
                Navigator.pop(sheetContext);
                showVendorPaymentMethodForm(context, ref, kind: VendorPaymentMethodKind.mobileMoney);
              },
            ),
            const SizedBox(height: 10),
            _KindTile(
              icon: Icons.account_balance_outlined,
              label: 'Bank transfer',
              sub: 'Payouts sent directly to your bank account',
              onTap: () {
                Navigator.pop(sheetContext);
                showVendorPaymentMethodForm(context, ref, kind: VendorPaymentMethodKind.bankTransfer);
              },
            ),
            if (!hasCashOnDelivery) ...[
              const SizedBox(height: 10),
              _KindTile(
                icon: Icons.payments_outlined,
                label: 'Cash on delivery',
                sub: 'Collect payment in person at drop-off or delivery',
                onTap: () {
                  ref.read(vendorPaymentMethodsProvider.notifier).add(
                    VendorPaymentMethod(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      kind: VendorPaymentMethodKind.cashOnDelivery,
                    ),
                  );
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _KindTile extends StatelessWidget {
  const _KindTile({required this.icon, required this.label, required this.sub, required this.onTap});

  final IconData icon;
  final String label;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.creamDark)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(13)),
              alignment: Alignment.center,
              child: Icon(icon, size: 19, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(sub, style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    ),
  );
}

/// The details form for one payout method — phone number (Mobile Money) or
/// bank account fields (Bank transfer). Pass [existing] to edit a saved
/// method in place instead of adding a new one.
void showVendorPaymentMethodForm(
  BuildContext context,
  WidgetRef ref, {
  required VendorPaymentMethodKind kind,
  VendorPaymentMethod? existing,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _PaymentMethodFormSheet(ref: ref, kind: kind, existing: existing),
  );
}

class _PaymentMethodFormSheet extends StatefulWidget {
  const _PaymentMethodFormSheet({required this.ref, required this.kind, this.existing});

  final WidgetRef ref;
  final VendorPaymentMethodKind kind;
  final VendorPaymentMethod? existing;

  @override
  State<_PaymentMethodFormSheet> createState() => _PaymentMethodFormSheetState();
}

class _PaymentMethodFormSheetState extends State<_PaymentMethodFormSheet> {
  late final _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
  late final _bankNameCtrl = TextEditingController(text: widget.existing?.bankName ?? '');
  late final _accountNumberCtrl = TextEditingController(text: widget.existing?.accountNumber ?? '');
  late final _accountHolderCtrl = TextEditingController(text: widget.existing?.accountHolder ?? '');
  String? _error;

  bool get _isMobileMoney => widget.kind == VendorPaymentMethodKind.mobileMoney;
  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _accountHolderCtrl.dispose();
    super.dispose();
  }

  MobileMoneyProvider? get _detectedProvider => detectMobileProvider(_digitsOnly(_phoneCtrl.text));

  void _save() {
    if (_isMobileMoney) {
      final digits = _digitsOnly(_phoneCtrl.text);
      final provider = detectMobileProvider(digits);
      if (digits.length != 10 || provider == null) {
        setState(() => _error = 'Enter a valid mobile money number.');
        return;
      }
      final method = VendorPaymentMethod(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        kind: widget.kind,
        provider: provider.name,
        phone: digits,
      );
      _commit(method);
      return;
    }

    final bankName = _bankNameCtrl.text.trim();
    final accountNumber = _digitsOnly(_accountNumberCtrl.text);
    final accountHolder = _accountHolderCtrl.text.trim();
    if (bankName.isEmpty) {
      setState(() => _error = 'Enter your bank name.');
      return;
    }
    if (accountNumber.length < 6) {
      setState(() => _error = 'Enter a valid account number.');
      return;
    }
    if (accountHolder.isEmpty) {
      setState(() => _error = 'Enter the account holder name.');
      return;
    }
    final method = VendorPaymentMethod(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      kind: widget.kind,
      bankName: bankName,
      accountNumber: accountNumber,
      accountHolder: accountHolder,
    );
    _commit(method);
  }

  void _commit(VendorPaymentMethod method) {
    final notifier = widget.ref.read(vendorPaymentMethodsProvider.notifier);
    if (_isEditing) {
      notifier.update(method);
    } else {
      notifier.add(method);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                _sheetHandle(),
                Text(
                  _isEditing
                      ? 'Edit ${vendorPaymentMethodKindLabel(widget.kind)}'
                      : 'Add ${vendorPaymentMethodKindLabel(widget.kind)}',
                  style: AppText.serif(fontSize: 22),
                ),
                const SizedBox(height: 3),
                Text(
                  'Saved to your vendor account for payouts',
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                if (_isMobileMoney) ..._mobileMoneyFields() else ..._bankFields(),
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
                            child: Text('Cancel', style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.muted)),
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
                              _isEditing ? 'Save changes' : 'Save method',
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
        ),
      ),
    );
  }

  List<Widget> _mobileMoneyFields() {
    final provider = _detectedProvider;
    return [
      _Field(
        label: 'Mobile money number',
        hint: '0754 111 222',
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        onChanged: (_) => setState(() {}),
        trailing: provider == null ? null : MobileMoneyLogo(provider: provider, size: 32),
      ),
      const SizedBox(height: 10),
      AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: provider == null
            ? Text(
                "We'll detect your provider automatically from the number",
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
              )
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    MobileMoneyLogo(provider: provider, size: 34),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        provider.name,
                        style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.teal),
                  ],
                ),
              ),
      ),
    ];
  }

  List<Widget> _bankFields() {
    return [
      _Field(label: 'Bank name', hint: 'CRDB Bank', controller: _bankNameCtrl),
      const SizedBox(height: 12),
      _Field(label: 'Account holder name', hint: 'Amara Reed', controller: _accountHolderCtrl),
      const SizedBox(height: 12),
      _Field(label: 'Account number', hint: '0123456789', controller: _accountNumberCtrl, keyboardType: TextInputType.number),
    ];
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.trailing,
    this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
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
