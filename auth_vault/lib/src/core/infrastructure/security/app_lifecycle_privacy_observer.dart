import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vault_pass_mobile/src/common/constants/colors.dart';
import 'package:vault_pass_mobile/src/common/constants/dimen.dart';
import 'package:vault_pass_mobile/src/core/presentation/widgets/text.dart';

class PrivacyCurtainContainer extends StatefulWidget {
  final Widget child;
  const PrivacyCurtainContainer({super.key, required this.child});
  @override
  State<PrivacyCurtainContainer> createState() => _PrivacyCurtainContainerState();
}

class _PrivacyCurtainContainerState extends State<PrivacyCurtainContainer> with WidgetsBindingObserver {
  bool _isObfuscated = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (!_isObfuscated) setState(() => _isObfuscated = true);
    } else if (state == AppLifecycleState.resumed) {
      if (_isObfuscated) setState(() => _isObfuscated = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isObfuscated)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: UIColors.canvas.withValues(alpha: 0.92),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Dimen.spaceLg),
                      decoration: BoxDecoration(
                        color: UIColors.canvasSoft,
                        borderRadius: BorderRadius.circular(Dimen.radiusMd),
                        border: Border.all(color: UIColors.primary, width: 1),
                      ),
                      child: Column(
                        children: [
                          AppText.eyebrow('DEFENSE SHIELD'),
                          const SizedBox(height: 8),
                          AppText.mono('[PRIVACY CURTAIN ACTIVE]', color: UIColors.primary),
                          const SizedBox(height: 4),
                          AppText.regular('Display obfuscated for app switcher', color: UIColors.mute, fontSize: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
