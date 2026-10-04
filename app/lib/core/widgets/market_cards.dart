import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_image.dart';
import 'tappable.dart';

const _n600 = Color(0xFF354764);
const _cardBorder = Color(0x14000000);

TextStyle _poppins(double size, FontWeight w, Color c) => TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: size,
      fontWeight: w,
      color: c,
    );

/// Small outlined pill ("Borrow", "Request service").
class OutlinePillButton extends StatelessWidget {
  const OutlinePillButton(
      {super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: Container(
        height: 32.6,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4000),
          border: Border.all(color: AppColors.primary, width: 0.9),
        ),
        child: Text(label,
            style: _poppins(14, FontWeight.w500, AppColors.primary)),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(
      {super.key, required this.product, required this.onBorrow, this.onTap});
  final Product product;
  final VoidCallback onBorrow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap ?? onBorrow,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder, width: 0.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5.5),
              child: SizedBox(
                height: 88.5,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(product.image, fit: BoxFit.cover),
                    Positioned(
                      top: 8.8,
                      right: 9,
                      child: _RatingPill(product.rating),
                    ),
                    if (product.pricePerDay > 0)
                      Positioned(
                        left: 7,
                        bottom: 6,
                        child: _PricePill(product.priceLabel),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            SizedBox(
              height: 36,
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _poppins(13.3, FontWeight.w500, AppColors.black)
                    .copyWith(height: 1.2),
              ),
            ),
            const SizedBox(height: 7),
            _DetailRow(
                'assets/icons/location.svg',
                product.distanceKm == null
                    ? product.location
                    : '${product.distanceLabel.replaceAll(' away', '')} · ${product.location}'),
            const SizedBox(height: 3.5),
            _DetailRow('assets/icons/time.svg', product.availability),
            const SizedBox(height: 3.5),
            _DetailRow('assets/icons/naira.svg', product.collateralLabel),
            const SizedBox(height: 14),
            OutlinePillButton(label: 'Borrow', onTap: onBorrow),
          ],
        ),
      ),
    );
  }
}

class _PricePill extends StatelessWidget {
  const _PricePill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(label, style: _poppins(10.5, FontWeight.w500, Colors.white)),
    );
  }
}

class _DistancePill extends StatelessWidget {
  const _DistancePill(this.km);
  final double km;

  @override
  Widget build(BuildContext context) {
    final t =
        km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(t, style: _poppins(10.5, FontWeight.w400, AppColors.black)),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill(this.rating);
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/star.svg', width: 17.7, height: 17.7),
          const SizedBox(width: 1),
          Text(rating.toStringAsFixed(1),
              style: _poppins(12.4, FontWeight.w400, AppColors.black)),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.icon, this.text);
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(icon, width: 17.7, height: 17.7),
        const SizedBox(width: 3.5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _poppins(12.4, FontWeight.w400, _n600),
          ),
        ),
      ],
    );
  }
}

class ServiceCard extends StatelessWidget {
  const ServiceCard(
      {super.key, required this.service, required this.onRequest});
  final ServiceItem service;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onRequest,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _cardBorder, width: 0.9),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5.5),
              child: SizedBox(
                height: 88.5,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(service.image, fit: BoxFit.cover),
                    if (service.price != null)
                      Positioned(
                        left: 7,
                        bottom: 6,
                        child: _PricePill(naira(service.price!)),
                      ),
                    if (service.distanceKm != null)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: _DistancePill(service.distanceKm!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(service.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _poppins(13.3, FontWeight.w500, AppColors.black)),
            const SizedBox(height: 7),
            SizedBox(
              height: 57,
              child: Text(
                service.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: _poppins(12.4, FontWeight.w400, _n600)
                    .copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 14),
            OutlinePillButton(label: 'Request service', onTap: onRequest),
          ],
        ),
      ),
    );
  }
}
