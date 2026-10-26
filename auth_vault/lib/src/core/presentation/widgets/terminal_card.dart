import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';
import '../../../common/constants/dimen.dart';

class TerminalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool highlighted;
  final VoidCallback? onTap;
  const TerminalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Dimen.spaceLg),
    this.highlighted = false,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: UIColors.canvas,
        borderRadius: BorderRadius.circular(Dimen.radiusMd),
        border: Border.all(
          color: highlighted ? UIColors.primary : UIColors.hairline,
          width: 1,
        ),
      ),
      child: child,
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimen.radiusMd),
        child: content,
      );
    }
    return content;
  }
}
