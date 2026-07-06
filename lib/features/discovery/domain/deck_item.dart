import '../../keo/domain/keo.dart';
import 'candidate.dart';

/// Deck Đôi giờ trộn 2 loại thẻ: ứng viên thật và thẻ quảng bá Kèo.
sealed class DeckItem {
  const DeckItem();
}

class CandidateItem extends DeckItem {
  const CandidateItem(this.candidate);
  final Candidate candidate;
}

class KeoPromoItem extends DeckItem {
  const KeoPromoItem(this.keo);
  final Keo keo;
}

/// Chèn 1 thẻ Kèo sau mỗi [every] ứng viên, tối đa [maxPromos] thẻ/deck.
/// Kèo của chính mình (host/đã xin vào) không quảng bá lại cho mình.
List<DeckItem> interleaveDeck({
  required List<Candidate> candidates,
  required List<Keo> keos,
  int every = 5,
  int maxPromos = 2,
}) {
  final promos = keos.where((k) => !k.isMine).take(maxPromos).toList();
  final items = <DeckItem>[];
  var promoIdx = 0;
  for (var i = 0; i < candidates.length; i++) {
    if (i > 0 && i % every == 0 && promoIdx < promos.length) {
      items.add(KeoPromoItem(promos[promoIdx++]));
    }
    items.add(CandidateItem(candidates[i]));
  }
  if (candidates.length >= every &&
      candidates.length % every == 0 &&
      promoIdx < promos.length) {
    items.add(KeoPromoItem(promos[promoIdx++]));
  }
  return items;
}
