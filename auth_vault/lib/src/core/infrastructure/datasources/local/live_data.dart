import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '../../../../shared/router/router_key_manager.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/dimen.dart';

class LiveData {
  LiveData._();
  static BuildContext? get mainContext => GlobalKeyManager.instance.root.currentContext;
  static void showError({BuildContext? context, required String msg}) {
    final ctx = context ?? mainContext;
    if (ctx == null || !ctx.mounted) return;
    Flushbar(
      messageText: Text(msg, style: const TextStyle(color: UIColors.ink, fontSize: 13)),
      duration: const Duration(seconds: 3),
      backgroundColor: UIColors.canvasSoft,
      borderColor: UIColors.error,
      borderWidth: 1,
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(Dimen.radiusSm),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ).show(ctx);
  }
  static void showSuccess({BuildContext? context, required String msg}) {
    final ctx = context ?? mainContext;
    if (ctx == null || !ctx.mounted) return;
    Flushbar(
      messageText: Text(msg, style: const TextStyle(color: UIColors.ink, fontSize: 13)),
      duration: const Duration(seconds: 3),
      backgroundColor: UIColors.canvasSoft,
      borderColor: UIColors.primary,
      borderWidth: 1,
      flushbarPosition: FlushbarPosition.TOP,
      borderRadius: BorderRadius.circular(Dimen.radiusSm),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ).show(ctx);
  }
}
