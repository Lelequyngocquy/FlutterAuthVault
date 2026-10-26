import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../common/constants/colors.dart';
import '../../../common/constants/dimen.dart';
import '../../../core/presentation/widgets/text.dart';

class ScrambledNumpad extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  const ScrambledNumpad({
    super.key,
    this.pinLength = 6,
    required this.onCompleted,
    this.onChanged,
  });
  @override
  State<ScrambledNumpad> createState() => _ScrambledNumpadState();
}

class _ScrambledNumpadState extends State<ScrambledNumpad> {
  late List<int> _digits;
  String _enteredPin = '';
  @override
  void initState() {
    super.initState();
    _scrambleKeypad();
  }
  void _scrambleKeypad() {
    final list = List<int>.generate(10, (index) => index);
    list.shuffle();
    _digits = list;
  }
  void _onDigitPressed(int digit) {
    HapticFeedback.lightImpact();
    if (_enteredPin.length < widget.pinLength) {
      setState(() => _enteredPin += digit.toString());
      widget.onChanged?.call(_enteredPin);
      if (_enteredPin.length == widget.pinLength) {
        widget.onCompleted(_enteredPin);
      }
    }
  }
  void _onBackspacePressed() {
    HapticFeedback.lightImpact();
    if (_enteredPin.isNotEmpty) {
      setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
      widget.onChanged?.call(_enteredPin);
    }
  }
  void _onClearPressed() {
    HapticFeedback.mediumImpact();
    setState(() {
      _enteredPin = '';
      _scrambleKeypad();
    });
    widget.onChanged?.call('');
  }
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.pinLength, (index) {
                bool filled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? UIColors.primary : UIColors.canvasSoft,
                    border: Border.all(
                      color: filled ? UIColors.primary : UIColors.hairline,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) {
                  return _buildActionButton('CLR', _onClearPressed);
                } else if (index == 10) {
                  return _buildDigitButton(_digits[9]);
                } else if (index == 11) {
                  return _buildActionButton('DEL', _onBackspacePressed);
                }
                return _buildDigitButton(_digits[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildDigitButton(int digit) {
    return Material(
      color: UIColors.canvasSoft,
      borderRadius: BorderRadius.circular(Dimen.radiusSm),
      child: InkWell(
        onTap: () => _onDigitPressed(digit),
        borderRadius: BorderRadius.circular(Dimen.radiusSm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimen.radiusSm),
            border: Border.all(color: UIColors.hairline, width: 1),
          ),
          alignment: Alignment.center,
          child: AppText.mono(
            digit.toString(),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: UIColors.ink,
          ),
        ),
      ),
    );
  }
  Widget _buildActionButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(Dimen.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimen.radiusSm),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimen.radiusSm),
            border: Border.all(color: UIColors.hairline.withValues(alpha: 0.5), width: 1),
          ),
          alignment: Alignment.center,
          child: AppText.mono(label, fontSize: 13, color: UIColors.mute),
        ),
      ),
    );
  }
}
