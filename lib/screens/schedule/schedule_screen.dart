import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/app_icons.dart';
import '../../data/mock_data.dart';
import '../../state/client_preferences_state.dart';
import '../../state/fulfillment_state.dart';
import '../../state/schedule_state.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/location.dart';
import '../../widgets/map_grid_painter.dart';
import '../../widgets/payment_processing.dart';
import '../../widgets/primary_cta_bar.dart';
import '../../widgets/radio_option_card.dart';
import '../../widgets/round_back_button.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  bool _locating = false;
  bool _quotingLocal = false;
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

  /// Auto-runs the delivery quote whenever the pickup location changes —
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

  Future<void> _runQuote(int seed) async {
    if (_quotingLocal) return;
    _quotingLocal = true;
    final language = ref.read(clientPreferencesProvider).language;
    final messenger = ScaffoldMessenger.of(context);
    final fulfillment = ref.read(fulfillmentProvider.notifier);
    final fee = deliveryFeeFor(seed);
    final driver = nearestDriverFor(seed);
    fulfillment.setQuoting(true);
    try {
      await showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.clientSurfaceRaised(context),
        barrierColor: Colors.black54,
        isDismissible: false,
        enableDrag: false,
        builder: (sheetContext) {
          Future.delayed(const Duration(milliseconds: 2200), () {
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          });
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + MediaQuery.of(context).padding.bottom),
            child: PaymentProcessing(
              title: clientLabel('Finding a driver', 'Kumtafuta dereva', language),
              subtitle: clientLabel(
                'Checking the area and matching your pickup with the nearest driver…',
                'Tunaangalia eneo na kumuunganisha dereva wa karibu na mzigo wako…',
                language,
              ),
              center: const Icon(Icons.local_shipping_outlined, color: AppColors.cream, size: 30),
            ),
          );
        },
      );
      fulfillment.finishQuote(fee: fee, driver: driver);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(clientLabel(
              '$driver matched to your pickup — delivery TZS ${formatMoney(fee.toDouble())}',
              '$driver ameunganishwa na mzigo wako — usafirishaji TZS ${formatMoney(fee.toDouble())}',
              language,
            )),
          ),
        );
      }
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

    ref.listen(scheduleProvider, (prev, next) {
      if (prev?.addrIndex != next.addrIndex) _maybeQuote();
    });

    final mapLabel = schedule.isCurrentLocation
        ? schedule.currentLocation
        : kAddresses[schedule.addrIndex].line;

    final quoteReady = fulfillment.deliveryFeeTzs > 0;
    final ctaLabel = () {
      if (!isDelivery) return clientLabel('Continue to checkout', 'Endelea kwenye kulipa', language);
      if (quoting || !quoteReady) return clientLabel('Finding your driver…', 'Kumtafuta dereva wako…', language);
      return clientLabel('Continue to checkout', 'Endelea kwenye kulipa', language);
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
                if (quoteReady) ...[
                  const SizedBox(height: 14),
                  _DriverAssignedCard(driver: fulfillment.driver, fee: fulfillment.deliveryFeeTzs, language: language),
                ],
                _SectionLabel(clientLabel('Pickup address', 'Anwani ya mzigo', language)),
                Column(
                  children: [
                    for (var i = 0; i < kAddresses.length; i++) ...[
                      RadioOptionCard(
                        label: kAddresses[i].label,
                        sub: kAddresses[i].line,
                        selected: schedule.addrIndex == i,
                        leading: _AddressIcon(icon: i == 0 ? AppIcons.home : AppIcons.office),
                        onTap: () => notifier.pickAddress(i),
                      ),
                      if (i != kAddresses.length - 1) const SizedBox(height: 10),
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
                  itemCount: kDays.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 9),
                  itemBuilder: (_, i) {
                    final active = schedule.dayIndex == i;
                    return _DayChip(
                      dow: kDays[i].dow,
                      num: kDays[i].num,
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
        onPressed: isDelivery && !quoteReady ? () {} : () => context.push('/checkout'),
      ),
    );
  }
}

class _DriverAssignedCard extends StatelessWidget {
  const _DriverAssignedCard({required this.driver, required this.fee, required this.language});

  final String driver;
  final int fee;
  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.tealMuted,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: const Icon(Icons.person_pin_circle_outlined, size: 22, color: AppColors.cream),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(clientLabel('Driver assigned', 'Dereva amepewa mzigo', language), style: AppText.eyebrow(color: AppColors.teal)),
          const SizedBox(height: 2),
          Text(driver, style: AppText.sans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.clientText(context))),
          const SizedBox(height: 2),
          Text(clientLabel('Delivery fee TZS ${formatMoney(fee.toDouble())}', 'Nauli ya usafirishaji TZS ${formatMoney(fee.toDouble())}', language), style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.clientSecondaryText(context))),
        ])),
        const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.teal),
      ]),
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
                Text(clientLabel('Pay at the shop — no delivery fee', 'Ulipa dukani — hakuna nauli', language), style: AppText.sans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.teal)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A stylised map preview of the pickup area — a fixed-height, properly
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
                  locating ? 'Finding your location…' : label,
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