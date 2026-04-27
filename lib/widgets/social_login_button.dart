import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialLoginButton extends StatelessWidget {
  final String svgAsset;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool hasBorder;
  final double? iconSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const SocialLoginButton({
    super.key,
    required this.svgAsset,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.hasBorder = false,
    this.iconSize,
    this.fontWeight = FontWeight.bold,
    this.letterSpacing = -0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: hasBorder ? Border.all(color: const Color(0xFFDADCE0), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                left: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SvgPicture.asset(
                    svgAsset,
                    width: iconSize ?? 22,
                    height: iconSize ?? 22,
                    colorFilter: (svgAsset.contains('google')) ? null : ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                ),
              ),
              Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor, 
                    fontSize: 15, 
                    fontWeight: fontWeight,
                    letterSpacing: letterSpacing,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
