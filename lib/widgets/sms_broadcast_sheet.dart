import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Bottom sheet for package/promo SMS broadcasts: audience picker
/// (all past customers vs loyal ≥ N orders), live count + contact list,
/// message preview, then confirm-send.
Future<void> showSmsBroadcastSheet({
  required BuildContext context,
  required String title,
  required Future<Map<String, dynamic>> Function({required String audience, required int minOrders}) loadAudience,
  required Future<Map<String, dynamic>> Function({required String audience, required int minOrders}) send,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _BroadcastSheet(title: title, loadAudience: loadAudience, send: send),
  );
}

class _BroadcastSheet extends StatefulWidget {
  const _BroadcastSheet({required this.title, required this.loadAudience, required this.send});

  final String title;
  final Future<Map<String, dynamic>> Function({required String audience, required int minOrders}) loadAudience;
  final Future<Map<String, dynamic>> Function({required String audience, required int minOrders}) send;

  @override
  State<_BroadcastSheet> createState() => _BroadcastSheetState();
}

class _BroadcastSheetState extends State<_BroadcastSheet> {
  String _audience = 'all';
  final _minCtrl = TextEditingController(text: '5');
  bool _loading = true;
  bool _sending = false;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    super.dispose();
  }

  int get _minOrders => int.tryParse(_minCtrl.text.trim()) ?? 5;

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await widget.loadAudience(audience: _audience, minOrders: _minOrders);
      if (!mounted) return;
      setState(() {
        _data = (res['data'] as Map<String, dynamic>?) ?? res;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _sending = true);
    try {
      final res = await widget.send(audience: _audience, minOrders: _minOrders);
      if (!mounted) return;
      Navigator.of(context).pop();
      final ok = res['success'] == true;
      final d = (res['data'] as Map?) ?? {};
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? (res['message'] as String? ?? 'SMS sent.') : (res['message'] as String? ?? 'Send failed.')),
          backgroundColor: ok ? AppColors.teal : AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      if (ok) {
        // Surface how many were reached vs skipped for bad numbers.
        debugPrint('sms broadcast: sent=${d['sent']} skipped=${d['skipped_invalid']} via=${d['credit_source']}');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.danger, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ((_data?['customers'] as List?) ?? []).whereType<Map>().toList();
    final shown = customers.take(8).toList();
    final quota = (_data?['quota'] as Map?) ?? {};
    final allowed = quota['allowed'] == true;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 22, right: 22, top: 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.creamDark, borderRadius: BorderRadius.circular(3)))),
              const SizedBox(height: 14),
              Text(widget.title, style: AppText.serif(fontSize: 20)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _AudienceChip(label: 'All customers', selected: _audience == 'all', onTap: () { setState(() => _audience = 'all'); _fetch(); }),
                  const SizedBox(width: 8),
                  _AudienceChip(label: 'Loyal (≥ N orders)', selected: _audience == 'loyal', onTap: () { setState(() => _audience = 'loyal'); _fetch(); }),
                  const SizedBox(width: 8),
                  if (_audience == 'loyal')
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: _minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'N', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        onSubmitted: (_) => _fetch(),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_error != null)
                Text(_error!, style: AppText.sans(fontSize: 13, color: AppColors.danger))
              else ...[
                Text(
                  '${_data?['valid'] ?? 0} reachable · ${quota['remaining_plan'] ?? 0} plan + ${quota['remaining_extra'] ?? 0} extra left',
                  style: AppText.sans(fontSize: 13, fontWeight: FontWeight.w800, color: allowed ? AppColors.teal : AppColors.danger),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14)),
                  child: Text('${_data?['message'] ?? ''}', style: AppText.sans(fontSize: 12.5, height: 1.5)),
                ),
                const SizedBox(height: 8),
                for (final c in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text('${c['name']}', style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                        Text('${c['phone'] ?? ''} · ${c['orders_count']} orders', style: AppText.sans(fontSize: 11.5, color: AppColors.muted)),
                      ],
                    ),
                  ),
                if (customers.length > shown.length)
                  Text('+ ${customers.length - shown.length} more…', style: AppText.sans(fontSize: 11.5, color: AppColors.muted)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (!allowed || _sending || ((_data?['valid'] ?? 0) as int) == 0) ? null : _confirm,
                    child: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Send to ${_data?['valid'] ?? 0} customers', style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                if (!allowed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('${quota['reason'] ?? 'Not enough SMS — request more from the dashboard.'}', style: AppText.sans(fontSize: 12, color: AppColors.danger)),
                  ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.teal : Colors.white,
          border: Border.all(color: selected ? AppColors.teal : AppColors.creamDark),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: AppText.sans(fontSize: 12, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.slate)),
      ),
    );
  }
}
