import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../utils/location.dart';

/// A plain-looking address [TextField] that shows a live dropdown of
/// [AddressSuggestion]s (from Nominatim/OSM) beneath it as the customer
/// types, debounced so every keystroke doesn't fire a network request.
/// Picking a suggestion fills [controller] with its label and reports the
/// suggestion's coordinates via [onSelected].
class AddressSearchField extends StatefulWidget {
  const AddressSearchField({super.key, required this.controller, required this.hint, required this.onSelected, this.autofocus = false});

  final TextEditingController controller;
  final String hint;
  final ValueChanged<AddressSuggestion> onSelected;
  final bool autofocus;

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  Timer? _debounce;
  List<AddressSuggestion> _suggestions = const [];
  bool _loading = false;

  /// True right after [_select] programmatically overwrites the controller
  /// text, so that resulting `onChanged` call doesn't immediately re-search
  /// and reopen the dropdown it just closed.
  bool _suppressNextChange = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String text) {
    if (_suppressNextChange) {
      _suppressNextChange = false;
      return;
    }
    _debounce?.cancel();
    if (text.trim().length < 3) {
      setState(() {
        _suggestions = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await searchAddressSuggestions(text);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  void _select(AddressSuggestion suggestion) {
    _suppressNextChange = true;
    widget.controller.value = TextEditingValue(
      text: suggestion.label,
      selection: TextSelection.collapsed(offset: suggestion.label.length),
    );
    setState(() => _suggestions = const []);
    widget.onSelected(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  controller: widget.controller,
                  autofocus: widget.autofocus,
                  onChanged: _onChanged,
                  style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700),
                  decoration: InputDecoration.collapsed(
                    hintText: widget.hint,
                    hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.muted),
                  ),
                ),
              ),
              if (_loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.creamDark),
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _suggestions.length; i++)
                  InkWell(
                    onTap: () => _select(_suggestions[i]),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: i == _suggestions.length - 1 ? Colors.transparent : AppColors.creamDark),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_suggestions[i].label, style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
