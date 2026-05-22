import 'dart:math';

import 'package:flutter/material.dart';

import '../models/wardrobe_item.dart';
import '../theme.dart';

class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.previewed,
    required this.onTap,
    required this.onAction,
    required this.onWatchAd,
    required this.adProgressText,
    super.key,
  });

  final WardrobeItem item;
  final bool owned;
  final bool equipped;
  final bool previewed;
  final VoidCallback onTap;
  final VoidCallback onAction;
  final VoidCallback? onWatchAd;
  final String? adProgressText;

  @override
  Widget build(BuildContext context) {
    final borderColor = equipped
        ? kGold
        : (previewed
              ? item.rarity.color
              : item.rarity.color.withValues(alpha: .35));
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 175;
        final adParts = (adProgressText ?? '0/0').split('/');
        final watched = int.tryParse(adParts.first) ?? 0;
        final required = item.rewardedAdsRequired;
        final adValue = required <= 0 ? 0.0 : watched / required;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: owned ? .09 : .045),
            border: Border.all(
              color: borderColor,
              width: equipped || previewed ? 2.2 : 1.2,
            ),
            boxShadow: [
              if (item.rarity.index >= WardrobeRarity.epic.index)
                BoxShadow(
                  color: item.rarity.color.withValues(
                    alpha: equipped ? .32 : .18,
                  ),
                  blurRadius: item.rarity == WardrobeRarity.mythic ? 28 : 18,
                ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: EdgeInsets.all(compact ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Center(
                      child: CustomPaint(
                        size: Size(compact ? 64 : 78, compact ? 54 : 66),
                        painter: _ItemPreviewPainter(
                          item: item,
                          dimmed: !owned,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: item.rarity.color.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            item.rarity.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.rarity.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Icon(
                        owned ? Icons.verified_rounded : Icons.lock_rounded,
                        size: 15,
                        color: owned ? kSafeGreen : Colors.white38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    owned ? (equipped ? 'Selected' : 'Owned') : item.unlockText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                  if (!owned && required > 0) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: adValue.clamp(0, 1),
                        minHeight: 5,
                        backgroundColor: Colors.white12,
                        color: kGlowBlue,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: equipped ? null : onAction,
                          style: FilledButton.styleFrom(
                            backgroundColor: owned
                                ? kGlowBlue
                                : item.rarity.color,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.white12,
                            padding: EdgeInsets.symmetric(
                              vertical: compact ? 7 : 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              equipped
                                  ? 'Selected'
                                  : (owned
                                        ? 'Select'
                                        : (item.price > 0
                                              ? '${item.price} coins'
                                              : 'Locked')),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!owned && onWatchAd != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onWatchAd,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: kGlowBlue.withValues(alpha: .7),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: compact ? 7 : 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Ad $adProgressText',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemPreviewPainter extends CustomPainter {
  const _ItemPreviewPainter({required this.item, required this.dimmed});

  final WardrobeItem item;
  final bool dimmed;

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = dimmed ? .36 : 1.0;
    final p = Paint()..color = item.primary.withValues(alpha: alpha);
    final s = Paint()..color = item.secondary.withValues(alpha: alpha);
    final center = Offset(size.width / 2, size.height / 2);
    switch (item.category) {
      case WardrobeCategory.character:
        canvas.drawCircle(
          Offset(center.dx, size.height * .28),
          size.width * .16,
          p,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(center.dx, size.height * .58),
              width: size.width * .34,
              height: size.height * .34,
            ),
            const Radius.circular(12),
          ),
          p,
        );
        canvas.drawCircle(Offset(center.dx - 7, size.height * .27), 2.5, s);
        canvas.drawCircle(Offset(center.dx + 7, size.height * .27), 2.5, s);
      case WardrobeCategory.hair:
        final hair = Path()
          ..moveTo(size.width * .25, size.height * .42)
          ..quadraticBezierTo(
            size.width * .5,
            size.height * .05,
            size.width * .75,
            size.height * .42,
          )
          ..quadraticBezierTo(
            size.width * .6,
            size.height * .32,
            size.width * .5,
            size.height * .5,
          )
          ..quadraticBezierTo(
            size.width * .4,
            size.height * .32,
            size.width * .25,
            size.height * .42,
          )
          ..close();
        canvas.drawPath(hair, p);
      case WardrobeCategory.hat:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: size.width * .58,
              height: size.height * .24,
            ),
            const Radius.circular(12),
          ),
          p,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center + const Offset(18, 6),
            width: 28,
            height: 8,
          ),
          s,
        );
      case WardrobeCategory.glasses:
        final stroke = Paint()
          ..color = item.primary.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center - const Offset(12, 0),
              width: 22,
              height: 16,
            ),
            const Radius.circular(5),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center + const Offset(12, 0),
              width: 22,
              height: 16,
            ),
            const Radius.circular(5),
          ),
          stroke,
        );
        canvas.drawLine(
          center - const Offset(1, 0),
          center + const Offset(1, 0),
          stroke..color = item.secondary.withValues(alpha: alpha),
        );
      case WardrobeCategory.tShirt:
      case WardrobeCategory.top:
      case WardrobeCategory.dress:
      case WardrobeCategory.jacket:
      case WardrobeCategory.pants:
      case WardrobeCategory.outfit:
        final torso = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: center,
            width: size.width * .5,
            height: size.height * .56,
          ),
          const Radius.circular(14),
        );
        canvas.drawRRect(torso, p);
        canvas.drawLine(
          Offset(center.dx, center.dy - size.height * .24),
          Offset(center.dx, center.dy + size.height * .24),
          Paint()
            ..color = item.secondary.withValues(alpha: alpha)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        if (item.category == WardrobeCategory.dress) {
          final skirt = Path()
            ..moveTo(center.dx - size.width * .23, center.dy + size.height * .1)
            ..lineTo(center.dx + size.width * .23, center.dy + size.height * .1)
            ..lineTo(
              center.dx + size.width * .32,
              center.dy + size.height * .34,
            )
            ..lineTo(
              center.dx - size.width * .32,
              center.dy + size.height * .34,
            )
            ..close();
          canvas.drawPath(skirt, s);
        }
      case WardrobeCategory.shoes:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(10, 25, 24, 18),
            const Radius.circular(9),
          ),
          p,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(40, 25, 24, 18),
            const Radius.circular(9),
          ),
          s,
        );
      case WardrobeCategory.watch:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 42, height: 28),
            const Radius.circular(8),
          ),
          p,
        );
        canvas.drawCircle(center, 8, s);
      case WardrobeCategory.bag:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 42, height: 44),
            const Radius.circular(10),
          ),
          p,
        );
        canvas.drawArc(
          Rect.fromCenter(
            center: center - const Offset(0, 12),
            width: 34,
            height: 30,
          ),
          pi,
          pi,
          false,
          Paint()
            ..color = item.secondary.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      case WardrobeCategory.earrings:
      case WardrobeCategory.necklace:
      case WardrobeCategory.bracelet:
        canvas.drawCircle(center - const Offset(13, 0), 8, p);
        canvas.drawCircle(center + const Offset(13, 0), 8, s);
        canvas.drawLine(
          center - const Offset(18, 18),
          center + const Offset(18, 18),
          Paint()
            ..color = item.secondary.withValues(alpha: alpha)
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          center + Offset(size.width * .17, -size.height * .14),
          4,
          s,
        );
      case WardrobeCategory.trail:
        for (var i = 0; i < 4; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: center - Offset(i * 9, 0),
              width: 44 - i * 6,
              height: 16 - i * 2,
            ),
            Paint()
              ..color = Color.lerp(
                item.primary,
                item.secondary,
                i / 4,
              )!.withValues(alpha: (.38 - i * .06) * alpha),
          );
        }
      case WardrobeCategory.effect:
        canvas.drawCircle(
          center,
          22,
          Paint()..color = item.primary.withValues(alpha: .2 * alpha),
        );
        canvas.drawCircle(
          center,
          12,
          Paint()..color = item.secondary.withValues(alpha: .55 * alpha),
        );
      case WardrobeCategory.bundle:
        canvas.drawCircle(center - const Offset(16, 0), 15, p);
        canvas.drawCircle(center + const Offset(8, -10), 15, s);
        canvas.drawCircle(
          center + const Offset(18, 11),
          13,
          Paint()..color = item.rarity.color.withValues(alpha: alpha),
        );
      case WardrobeCategory.roadTheme:
        final path = Path()
          ..moveTo(size.width * .5, 8)
          ..lineTo(size.width * .86, size.height - 8)
          ..lineTo(size.width * .14, size.height - 8)
          ..close();
        canvas.drawPath(
          path,
          Paint()
            ..shader = LinearGradient(
              colors: [item.primary, item.secondary],
            ).createShader(Offset.zero & size),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = item.secondary.withValues(alpha: alpha),
        );
    }
  }

  @override
  bool shouldRepaint(covariant _ItemPreviewPainter oldDelegate) =>
      oldDelegate.item != item || oldDelegate.dimmed != dimmed;
}
