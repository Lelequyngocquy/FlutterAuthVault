import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:vault_pass_mobile/src/common/constants/colors.dart';
import 'package:vault_pass_mobile/src/common/constants/dimen.dart';
import 'package:vault_pass_mobile/src/core/presentation/widgets/text.dart';

class PrivacyCurtainContainer extends StatefulWidget {
  final Widget child;
  const PrivacyCurtainContainer({super.key, required this.child});
  static final GlobalKey<PrivacyCurtainContainerState> globalKey = GlobalKey<PrivacyCurtainContainerState>();
  static void triggerPreview({Duration duration = const Duration(seconds: 3)}) {
    globalKey.currentState?.showPreview(duration);
  }
  @override
  State<PrivacyCurtainContainer> createState() => PrivacyCurtainContainerState();
}

class PrivacyCurtainContainerState extends State<PrivacyCurtainContainer> with WidgetsBindingObserver {
  bool _isObfuscated = false;
  Timer? _previewTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _previewTimer?.cancel();
    super.dispose();
  }
  void showPreview(Duration duration) {
    setState(() => _isObfuscated = true);
    _previewTimer?.cancel();
    _previewTimer = Timer(duration, () {
      if (mounted) setState(() => _isObfuscated = false);
    });
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
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_isObfuscated)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: UIColors.canvas.withValues(alpha: 0.92),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(Dimen.spaceLg),
                  decoration: BoxDecoration(
                    color: UIColors.canvasSoft,
                    borderRadius: BorderRadius.circular(Dimen.radiusMd),
                    border: Border.all(color: UIColors.primary, width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, color: UIColors.primary, size: 36),
                      const SizedBox(height: 12),
                      AppText.eyebrow('LÁ CHẮN BẢO VỆ'),
                      const SizedBox(height: 8),
                      AppText.mono('[RÈM BẢO MẬT ĐANG BẬT]', color: UIColors.primary, fontSize: 13),
                      const SizedBox(height: 6),
                      AppText.regular(
                        'Màn hình đã được làm mờ để chống chụp trộm khi chuyển ứng dụng',
                        color: UIColors.mute,
                        fontSize: 12,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
