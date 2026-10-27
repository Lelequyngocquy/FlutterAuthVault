import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';
import '../../../common/constants/dimen.dart';
import 'text.dart';

enum ButtonVariant { primary, outline, danger }

class AppButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final IconData? icon;
  final Widget? child;
  final bool enable;
  final bool loading;
  final double height;
  final double? width;
  final ButtonVariant variant;
  const AppButton.primary({
    super.key,
    required this.onTap,
    required this.title,
    this.icon,
    this.child,
    this.enable = true,
    this.loading = false,
    this.height = 48,
    this.width,
  }) : variant = ButtonVariant.primary;
  const AppButton.outline({
    super.key,
    required this.onTap,
    required this.title,
    this.icon,
    this.child,
    this.enable = true,
    this.loading = false,
    this.height = 48,
    this.width,
  }) : variant = ButtonVariant.outline;
  const AppButton.danger({
    super.key,
    required this.onTap,
    required this.title,
    this.icon,
    this.child,
    this.enable = true,
    this.loading = false,
    this.height = 48,
    this.width,
  }) : variant = ButtonVariant.danger;
  @override
  Widget build(BuildContext context) {
    final bg = switch (variant) {
      ButtonVariant.primary => enable ? UIColors.primary : UIColors.canvasSoft,
      ButtonVariant.outline => Colors.transparent,
      ButtonVariant.danger => Colors.transparent,
    };
    final border = switch (variant) {
      ButtonVariant.primary => Colors.transparent,
      ButtonVariant.outline => UIColors.hairline,
      ButtonVariant.danger => UIColors.error,
    };
    final textColor = switch (variant) {
      ButtonVariant.primary => enable ? UIColors.onPrimary : UIColors.mute,
      ButtonVariant.outline => UIColors.ink,
      ButtonVariant.danger => UIColors.error,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: width ?? double.infinity,
      ),
      child: SizedBox(
        width: width ?? double.infinity,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(Dimen.radiusSm),
          child: InkWell(
            onTap: (enable && !loading) ? onTap : null,
            borderRadius: BorderRadius.circular(Dimen.radiusSm),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 1),
                borderRadius: BorderRadius.circular(Dimen.radiusSm),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : child ??
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: textColor),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: AppText.semiBold(
                              title,
                              color: textColor,
                              fontSize: 13,
                              maxLines: 3,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
