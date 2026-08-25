import 'fulfillment_state.dart';

/// Whether adding an item from [shop] into the current basket would mix two
/// vendors into one order.
///
/// The basket is a single global cart keyed by item, and an order carries
/// exactly one `shop` through to fulfilment — so items from a second vendor
/// would be silently billed to, and picked up from, the first. True here
/// means the customer has to be asked before anything is added.
///
/// An empty basket belongs to nobody: adopting the new shop is free, and
/// `FulfillmentState.shop`'s seed value alone is not evidence of intent.
bool basketBelongsToOtherShop(Map<String, int> qty, FulfillmentState fulfillment, String shop) {
  if (fulfillment.shop == shop) return false;
  return qty.values.any((n) => n > 0);
}
