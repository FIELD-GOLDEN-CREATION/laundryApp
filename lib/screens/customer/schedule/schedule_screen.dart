import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../utils/cart_math.dart';
import '../../../utils/schedule_options.dart';
import '../../../models/address.dart';
import '../../../state/auth_state.dart';
import '../../../state/cart_state.dart';
import '../../../state/client_preferences_state.dart';
import '../../../state/fulfillment_state.dart';
import '../../../state/place_order_helper.dart';
import '../../../state/profile_state.dart';
import '../../../state/schedule_state.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/location.dart';
import '../../../widgets/map_grid_painter.dart';
import '../../../widgets/primary_cta_bar.dart';
import '../../../widgets/radio_option_card.dart';
import '../../../widgets/round_back_button.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _locating = false;
  bool _quotingLocal = false;
  bool _addressesRequested = false;
  int? _lastQuotedSeed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fulfillment = ref.read(fulfillmentProvider);
      if (fulfillment.isDelivery && fulfillment.deliveryFeeTzs == 0 && !fulfillment.quoting) {
        _maybeQuote();
      }
    });
  }

  Future<void> _locateMe() async {
    if (_locating) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _locating = true);
    try {
      final point = await locateUser();
      ref.read(scheduleProvider.notifier).setCurrentLocation(point.label);
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not get your location.')),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Auto-runs the delivery quote whenever the pickup location changes â€”
  /// Home, Office or "Locate me". Only skips when the exact same seed was
  /// already quoted (so rebuilds don't re-show the sheet).
  void _maybeQuote() {
    if (_quotingLocal) return;
    final fulfillment = ref.read(fulfillmentProvider);
    if (!fulfillment.isDelivery) return;
    final schedule = ref.read(scheduleProvider);
    final seed = schedule.addrIndex < 0 ? 0 : schedule.addrIndex;
    if (_lastQuotedSeed == seed && fulfillment.deliveryFeeTzs > 0) return;
    _lastQuotedSeed = seed;
    _runQuote(seed);
  }

  /// Places the order straight from scheduling â€” the client no longer pays
  /// up front, so there's nothing left for a separate checkout step to
  /// collect. `checkout_screen.dart` still exists but nothing routes to it.
  Future<void> _continueToConfirmation() async {
    if (gateGuest(ref, context, 'Log in to place your order â€” guests can browse everything else.')) return;
    final schedule = ref.read(scheduleProvider);
    final fulfillment = ref.read(fulfillmentProvider);
    final qty = ref.read(cartProvider);
    final priced = ref.read(fulfillmentProvider).pricedItems;
    final subtotal = cartSubtotal(qty, priced);
    final deliveryFee = fulfillment.isDelivery ? fulfillment.deliveryFeeTzs : 0;
    final total = subtotal + deliveryFee;
    final addresses = ref.read(profileProvider).addresses;
    final address = schedule.isCurrentLocation
        ? Address(label: 'Current location', line: schedule.currentLocation.isEmpty ? 'Current location' : schedule.currentLocation)
        : addresses[schedule.addrIndex.clamp(0, addresses.length - 1)];
    final days = upcomingDays();
    final day = days[schedule.dayIndex.clamp(0, days.length - 1)];
    final pickupSummary = '${day.dow} ${day.num}, ${kTimeSlots[schedule.slotIndex]}';

    final order = await placeCurrentOrder(
      ref,
      paymentMethod: '',
      pickup: pickupSummary,
      address: address.line,
      total: formatMoney(total),
    );
    if (!mounted) return;
    context.go('/order-confirmation', extra: order.id);
  }

  /// Quietly resolves the delivery fee/driver in the background â€” no modal
  /// or snackbar theatrics, since driver assignment is no longer surfaced at
  /// scheduling time. The CTA's "Finding your driverâ€¦" label already covers
  /// the `quoting` state, so this just needs to fill in the fee for the
  /// order total.
  Future<void> _runQuote(int seed) async {
    if (_quotingLocal) return;
    _quotingLocal = true;
    final fulfillment = ref.read(fulfillmentProvider.notifier);
    final fee = deliveryFeeFor(seed);
    final driver = nearestDriverFor(seed);
    fulfillment.setQuoting(true);
    try {
      await Future.delayed(const Duration(milliseconds: 900));
      fulfillment.finishQuote(fee: fee, driver: driver);
    } finally {
      _quotingLocal = false;
      if (mounted) fulfillment.setQuoting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(clientPreferencesProvider).language;
    final schedule = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);
    final fulfillment = ref.watch(fulfillmentProvider);
    final isDelivery = fulfillment.isDelivery;
    final quoting = fulfillment.quoting;

    // Saved addresses come from the customer profile (API-backed).
    final addresses = ref.watch(profileProvider.select((s) => s.addresses));
    final days = upcomingDays();

    // Ensure addresses are loaded once.
    if (addresses.isEmpty && !_addressesRequested) {
      _addressesRequested = true;
      Future.microtask(() => ref.read(profileProvider.notifier).loadAddresses());
    }

    ref.listen(scheduleProvider, (prev, next) {
      if (prev?.addrIndex != next.addrIndex) _maybeQuote();
    });

    final mapLabel = schedule.isCurrentLocation
        ? schedule.currentLocation
        : addresses.isNotEmpty ? addresses[schedule.addrIndex.clamp(0, addresses.length - 1)].line : schedule.currentLocation;

    final quoteReady = fulfillment.deliveryFeeTzs > 0;
    final ctaLabel = () {
      if (!isDelivery) return clientLabel('Place order', 'Weka oda', language);
      if (quoting || !quoteReady) return clientLabel('Finding your driverâ€¦', 'Kumtafuta dereva wakoâ€¦', language);
      return clientLabel('Place order', 'Weka oda', language);
    }();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RoundBackButton(onPressed: () => context.pop()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDelivery ? clientLabel('Schedule pickup', 'Ratibu kuchukua', language) : clientLabel('Plan your drop-off', 'Panga kupeleka', language),
                      style: AppText.serif(fontSize: 24, color: AppColors.clientText(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isDelivery) ...[
                _MapPreview(label: mapLabel, locating: _locating),
                _SectionLabel(clientLabel('Pickup address', 'Anwani ya mzigo', language)),
                Column(
                  children: [
                    for (var i = 0; i < addresses.length; i++) ...[
                      RadioOptionCard(
                        label: addresses[i].label,
                        sub: addresses[i].line,
                        selected: schedule.addrIndex == i,
                        leading: _AddressIcon(icon: i == 0 ? AppIcons.home : AppIcons.office),
                        onTap: () => notifier.pickAddress(i),
                      ),
                      if (i != addresses.length - 1) const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 10),
                    RadioOptionCard(
                      label: clientLabel('Locate me', 'Nipate', language),
                      sub: schedule.isCurrentLocation ? schedule.currentLocation : clientLabel('Use my current location (GPS)', 'Tumia eneo langu la sasa (GPS)', language),
                      selected: schedule.isCurrentLocation,
                      leading: _AddressIcon(icon: AppIcons.locate, bg: AppColors.amberLight, fg: AppColors.amber),
                      onTap: () => _locateMe(),
                    ),
                  ],
                ),
              ] else _ShopDropOffCard(shop: fulfillment.shop, language: language),
              _SectionLabel(isDelivery ? clientLabel('Pickup day', 'Siku ya kuchukua', language) : clientLabel('Drop-off day', 'Siku ya kupeleka', language)),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (_, i) {
                    final active = schedule.dayIndex == i;
                    return _DayChip(
                      dow: days[i].dow,
                      num: days[i].num,
                      active: active,
                      onTap: () => notifier.pickDay(i),
                    );
                  },
                ),
              ),
              _SectionLabel(clientLabel('Time window', 'Muda', language)),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.7,
                children: [
                  for (var i = 0; i < kTimeSlots.length; i++)
                    _TimeSlotChip(
                      label: kTimeSlots[i],
                      active: schedule.slotIndex == i,
                      onTap: () => notifier.pickSlot(i),
                    ),
                ],
              ),
              _SectionLabel(isDelivery ? clientLabel('Note for the driver', 'Ujumbe kwa dereva', language) : clientLabel('Note for the shop', 'Ujumbe kwa duka', language)),
              TextField(
                onChanged: notifier.setNote,
                maxLines: 3,
                style: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.clientText(context)),
                decoration: InputDecoration(
                  hintText: clientLabel(
                    'e.g. Ring the bell twice, bags are by the door',
                    'Mf. Piga hodi mara mbili, mifuko iko karibu na mlango',
                    language,
                  ),
                  hintStyle: AppText.sans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.clientSecondaryText(context)),
                  filled: true,
                  fillColor: AppColors.clientSurface(context),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: AppColors.clientBorder(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: AppColors.clientBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.teal),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PrimaryCtaBar(
        label: ctaLabel,
        hint: isDelivery && quoteReady ? formatMoney(fulfillment.deliveryFeeTzs.toDouble()) : null,
        onPressed: isDelivery && !quoteReady ? () {} : _continueToConfirmation,
      ),
    );
  }
}

class _ShopDropOffCard extends StatelessWidget {
  const _ShopDropOffCard({required this.shop, required this.language});

  final String shop;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.clientSurface(context),
        border: Border.all(color: AppColors.clientBorder(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: AppColors.tealMuted, borderRadius: BorderRadius.circular(15)),
            alignment: Alignment.center,
            child: const Icon(Icons.storefront_outlined, size: 22, color: AppColors.teal),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clientLabel('Drop off at', 'Peleka kwenye', language), style: AppText.eyebrow()),
                const SizedBox(height: 3),
                Text(shop, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
                const SizedBox(height: 2),
                Text(clientLabel('Pay at the shop â€” no delivery fee', 'Ulipa dukani â€” hakuna nauli', language), style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.teal)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stylised map preview of the pickup area â€” a fixed-height, properly
/// sized tile with a location pin and the selected address, so the location
/// reads visually instead of as a bare list row.
class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.label, required this.locating});

  final String label;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.tealMuted),
            CustomPaint(painter: MapGridPainter()),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.teal.withValues(alpha: 0.08)],
                ),
              ),
            ),
            Center(
              child: locating
                  ? const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.teal))
                  : const _MapPin(),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  locating ? 'Finding your locationâ€¦' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: const AppIcon(AppIcons.locationPin, size: 20, color: AppColors.cream),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 11),
      child: Text(text.toUpperCase(), style: AppText.eyebrow(color: AppColors.clientSecondaryText(context))),
    );
  }
}

class _AddressIcon extends StatelessWidget {
  const _AddressIcon({required this.icon, this.bg = AppColors.tealMuted, this.fg = AppColors.teal});

  final String icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(13)),
      alignment: Alignment.center,
      child: AppIcon(icon, size: 19, color: fg),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.dow, required this.num, required this.active, required this.onTap});

  final String dow;
  final String num;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.teal : AppColors.clientSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? AppColors.teal : AppColors.clientBorder(context), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Column(
              children: [
                Text(
                  dow,
                  style: AppText.sans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: (active ? AppColors.cream : AppColors.clientSecondaryText(context)).withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  num,
                  style: AppText.sans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: active ? AppColors.cream : AppColors.clientText(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  const _TimeSlotChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.tealMuted : AppColors.clientSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: active ? AppColors.teal : AppColors.clientBorder(context), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: AppText.sans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.teal : AppColors.clientText(context),
            ),
          ),
        ),
      ),
    );
  }
}
