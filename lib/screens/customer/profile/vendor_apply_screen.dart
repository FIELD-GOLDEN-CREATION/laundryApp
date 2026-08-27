import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/api_service.dart';
import '../../../state/profile_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';

const _kPlans = [
  _Plan(
    id: 'basic',
    name: 'Basic',
    nameSw: 'Msingi',
    price: 'Free',
    priceSw: 'Bure',
    period: '',
    periodSw: '',
    features: [
      'Up to 30 orders/month',
      'Basic analytics',
      'Standard support',
    ],
    featuresSw: [
      'Hadi oda 30 kwa mwezi',
      'Uchambuzi wa msingi',
      'Msaada wa kawaida',
    ],
  ),
  _Plan(
    id: 'pro',
    name: 'Pro',
    nameSw: 'Pro',
    price: 'TZS 75,000',
    priceSw: 'TZS 75,000',
    period: '/month',
    periodSw: '/mwezi',
    features: [
      'Unlimited orders',
      'Advanced analytics',
      'Priority support',
      'Featured listing',
    ],
    featuresSw: [
      'Oda zisizo na kikomo',
      'Uchambuzi wa hali ya juu',
      'Msaada wa kipaumbele',
      'Orodha inayoonekana zaidi',
    ],
    isPopular: true,
  ),
  _Plan(
    id: 'enterprise',
    name: 'Enterprise',
    nameSw: 'Enterprise',
    price: 'TZS 200,000',
    priceSw: 'TZS 200,000',
    period: '/month',
    periodSw: '/mwezi',
    features: [
      'Unlimited orders',
      'Full analytics suite',
      'Dedicated account manager',
      'Custom branding',
      'API access',
    ],
    featuresSw: [
      'Oda zisizo na kikomo',
      'Uchambuzi kamili',
      'Meneja wa akaunti mahsusi',
      'Uso wa chapa yako',
      'Upatikanaji wa API',
    ],
  ),
];

class _Plan {
  const _Plan({
    required this.id,
    required this.name,
    required this.nameSw,
    required this.price,
    required this.priceSw,
    required this.period,
    required this.periodSw,
    required this.features,
    required this.featuresSw,
    this.isPopular = false,
  });

  final String id, name, nameSw, price, priceSw, period, periodSw;
  final List<String> features, featuresSw;
  final bool isPopular;
}

class VendorApplyScreen extends ConsumerStatefulWidget {
  const VendorApplyScreen({super.key});

  @override
  ConsumerState<VendorApplyScreen> createState() => _VendorApplyScreenState();
}

class _VendorApplyScreenState extends ConsumerState<VendorApplyScreen> {
  int _step = 0; // 0 = plan selection, 1 = form, 2 = success
  String _selectedPlan = 'pro';
  bool _submitting = false;

  // Form controllers
  final _bizNameCtrl = TextEditingController();
  final _bizLocationCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _bizLocationCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _selectPlan(String planId) => setState(() => _selectedPlan = planId);

  void _continueToForm() => setState(() => _step = 1);

  void _backToPlans() => setState(() => _step = 0);

  Future<void> _submit() async {
    if (_bizNameCtrl.text.trim().isEmpty || _bizLocationCtrl.text.trim().isEmpty || _contactPhoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await api.submitVendorApplication(
        officeName: _bizNameCtrl.text.trim(),
        plan: _selectedPlan,
        officeLocation: _bizLocationCtrl.text.trim(),
        contactPhone: _contactPhoneCtrl.text.trim(),
        contactWhatsapp: _whatsappCtrl.text.trim().isEmpty ? null : _whatsappCtrl.text.trim(),
        businessDescription: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _step = 2;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit application. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(clientPreferencesProvider).language;
    final profile = ref.watch(profileProvider);
    final titles = ['Select Plan', 'Chagua Mpango', 'Your Details', 'Taarifa Zako', 'Application Submitted', 'Oda Imewasilishwa'];

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.slate,
        foregroundColor: AppColors.cream,
        title: Text(
          clientLabel(titles[_step * 2], titles[_step * 2 + 1], lang),
          style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          onPressed: () {
            if (_step == 1) {
              _backToPlans();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _step == 2 ? _buildSuccess(lang, profile) : _step == 1 ? _buildForm(lang, profile) : _buildPlanSelection(lang),
    );
  }

  // ── Step 0: Plan Selection ──────────────────────────────────────────────

  Widget _buildPlanSelection(String lang) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Text(
          clientLabel('Choose a plan that fits your business', 'Chagua mpango unaofaa biashara yako', lang),
          style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        for (final plan in _kPlans) ...[
          _PlanCard(
            plan: plan,
            selected: _selectedPlan == plan.id,
            lang: lang,
            onTap: () => _selectPlan(plan.id),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _continueToForm,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: Text(
                  clientLabel('Continue', 'Endelea', lang),
                  style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cream),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 1: Application Form ────────────────────────────────────────────

  Widget _buildForm(String lang, dynamic profile) {
    final selectedPlan = _kPlans.firstWhere((p) => p.id == _selectedPlan);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // Selected plan summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.tealMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  selectedPlan.name[0],
                  style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.cream),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientLabel(selectedPlan.name, selectedPlan.nameSw, lang),
                      style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.teal),
                    ),
                    Text(
                      '${selectedPlan.price}${clientLabel(selectedPlan.period, selectedPlan.periodSw, lang)}',
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _backToPlans,
                child: Text(
                  clientLabel('Change', 'Badilisha', lang),
                  style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section: Personal info
        Text(
          clientLabel('PERSONAL INFORMATION', 'TAARIFA BINAFSI', lang),
          style: AppText.eyebrow(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        _FormCard(
          children: [
            _FormField(
              label: clientLabel('Full Name', 'Jina Kamili', lang),
              hint: clientLabel('Enter your full name', 'Weka jina lako kamili', lang),
              controller: TextEditingController(text: profile.name),
              readOnly: true,
            ),
            _FormField(
              label: clientLabel('Email Address', 'Anwani ya Barua Pepe', lang),
              hint: clientLabel('Enter your email', 'Weka barua pepe yako', lang),
              controller: TextEditingController(text: profile.email),
              readOnly: true,
            ),
            _FormField(
              label: clientLabel('Phone Number', 'Nambari ya Simu', lang),
              hint: clientLabel('Enter your phone number', 'Weka nambari yako ya simu', lang),
              controller: TextEditingController(text: profile.phone),
              readOnly: true,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section: Business info
        Text(
          clientLabel('BUSINESS INFORMATION', 'TAARIFA ZA BIASHARA', lang),
          style: AppText.eyebrow(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        _FormCard(
          children: [
            _FormField(
              label: clientLabel('Business Name', 'Jina la Biashara', lang),
              hint: clientLabel('e.g. Koroma Cleaners', 'mf. Koroma Cleaners', lang),
              controller: _bizNameCtrl,
            ),
            _FormField(
              label: clientLabel('Business Location', 'Eneo la Biashara', lang),
              hint: clientLabel('e.g. 12 Chole Road, Masaki', 'mf. 12 Chole Road, Masaki', lang),
              controller: _bizLocationCtrl,
            ),
            _FormField(
              label: clientLabel('Contact Phone', 'Simu ya Mawasiliano', lang),
              hint: clientLabel('Phone for customers to reach you', 'Simu kwa wateja kukufikia', lang),
              controller: _contactPhoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            _FormField(
              label: clientLabel('WhatsApp (Optional)', 'WhatsApp (Hiari)', lang),
              hint: clientLabel('WhatsApp number if different', 'Nambari ya WhatsApp ikiwa tofauti', lang),
              controller: _whatsappCtrl,
              keyboardType: TextInputType.phone,
              isRequired: false,
            ),
            _FormField(
              label: clientLabel('Business Description', 'Maelezo ya Biashara', lang),
              hint: clientLabel('Tell us about your laundry services...', 'Tuambie kuhusu huduma zako za ufagaji...', lang),
              controller: _descriptionCtrl,
              maxLines: 3,
              isRequired: false,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: Material(
            color: AppColors.teal,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _submitting ? null : _submit,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.cream),
                      )
                    : Text(
                        clientLabel('Submit Application', 'Wasilisha Oda', lang),
                        style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cream),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Success ─────────────────────────────────────────────────────

  Widget _buildSuccess(String lang, dynamic profile) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.tealMuted,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.check_circle_rounded, size: 40, color: AppColors.teal),
            ),
            const SizedBox(height: 24),
            Text(
              clientLabel('Application Submitted!', 'Oda Imewasilishwa!', lang),
              style: AppText.serif(fontSize: 22, color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              clientLabel(
                'Thank you for your interest in becoming a vendor. Our team will review your application and get back to you within 24-48 hours.',
                'Asante kwa nia yako ya kuwa muuzaji. Timu yetu itakagua oda yako na itakurudia ndani ya masaa 24-48.',
                lang,
              ),
              style: AppText.sans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    child: Text(
                      clientLabel('Back to Profile', 'Rudi kwenye Wasifu', lang),
                      style: AppText.sans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.cream),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.lang,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.tealMuted : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? AppColors.teal : AppColors.creamDark,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.teal : AppColors.creamDark,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    clientLabel(plan.name, plan.nameSw, lang),
                    style: AppText.sans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate),
                  ),
                  if (plan.isPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        clientLabel('Most Popular', 'Maarufu Zaidi', lang),
                        style: AppText.sans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.amber),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    clientLabel(plan.price, plan.priceSw, lang),
                    style: AppText.sans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.teal),
                  ),
                  if (plan.period.isNotEmpty)
                    Text(
                      clientLabel(plan.period, plan.periodSw, lang),
                      style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              for (final feature in plan.features.asMap().entries) ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        clientLabel(
                          plan.features[feature.key],
                          plan.featuresSw[feature.key],
                          lang,
                        ),
                        style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                if (feature.key < plan.features.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.isRequired = true,
    this.maxLines = 1,
  });

  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly, isRequired;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.clientBorder(context)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted),
              ),
              if (isRequired)
                const Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            style: AppText.sans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: readOnly ? AppColors.muted : AppColors.slate,
            ),
            decoration: InputDecoration.collapsed(
              hintText: hint,
              hintStyle: AppText.sans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.muted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
