import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/dimen.dart';
import '../../../../core/domain/bloc_status.dart';
import '../../../../core/infrastructure/datasources/local/live_data.dart';
import '../../../../core/infrastructure/security/device_integrity_checker.dart';
import '../../../../core/presentation/widgets/button.dart';
import '../../../../core/presentation/widgets/status_pill.dart';
import '../../../../core/presentation/widgets/terminal_card.dart';
import '../../../../core/presentation/widgets/text.dart';
import '../../../../core/presentation/widgets/text_field.dart';
import '../../../../shared/router/router_key_manager.dart';
import '../../../pin_fallback/presentation/scrambled_numpad.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameCtrl = TextEditingController(text: 'admin');
  final TextEditingController _passwordCtrl = TextEditingController(text: 'admin123');
  IntegrityReport? _integrityReport;
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkBiometricSupport();
    _checkIntegrity();
  }
  Future<void> _checkIntegrity() async {
    final report = await DeviceIntegrityChecker.evaluateDevice();
    if (mounted) setState(() => _integrityReport = report);
  }
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UIColors.canvas,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == BlocStatus.success) {
              LiveData.showSuccess(msg: 'Identity authenticated successfully');
              context.go(RouterPath.dashboard);
            } else if (state.status == BlocStatus.error && state.message != null) {
              LiveData.showError(msg: state.message!);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Dimen.space2Xl, vertical: Dimen.spaceXl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const StatusPill(label: 'HARDWARE GUARDED', color: UIColors.primary),
                      if (_integrityReport != null)
                        StatusPill(
                          label: _integrityReport!.isSecure ? 'SYS: SECURE' : 'SYS: DEV/EMU',
                          color: _integrityReport!.isSecure ? UIColors.primary : UIColors.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AppText.eyebrow('ENTERPRISE IDENTITY HUB'),
                  const SizedBox(height: 8),
                  AppText.bold('AuthVault Security Gate', fontSize: 24),
                  const SizedBox(height: 8),
                  AppText.regular('Zero-trust biometric gate with scrambled PIN fallback', color: UIColors.mute, fontSize: 13),
                  const SizedBox(height: 28),
                  if (!state.isPinFallbackMode) ...[
                    TerminalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _usernameCtrl,
                            label: 'OPERATOR IDENTITY',
                            hint: 'Username / Agent ID',
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'CREDENTIAL SECRET',
                            hint: 'Password',
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          AppButton.primary(
                            onTap: () => context.read<AuthCubit>().loginWithPassword(
                              _usernameCtrl.text.trim(),
                              _passwordCtrl.text.trim(),
                            ),
                            loading: state.isLoading,
                            title: 'AUTHENTICATE CREDENTIALS',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton.outline(
                      onTap: () => context.read<AuthCubit>().loginWithBiometrics(),
                      loading: state.isLoading,
                      title: 'AUTHENTICATE BIOMETRICS (CHALLENGE-RESPONSE)',
                    ),
                    const SizedBox(height: 12),
                    AppButton.outline(
                      onTap: () => context.read<AuthCubit>().togglePinFallback(true),
                      title: 'SWITCH TO SCRAMBLED PIN FALLBACK',
                    ),
                  ] else ...[
                    TerminalCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.eyebrow('DEFENSE: ANTI-SHOULDER SURFING'),
                              const StatusPill(label: 'SHUFFLED 0-9', color: UIColors.primary),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ScrambledNumpad(
                            pinLength: 6,
                            onCompleted: (pin) => context.read<AuthCubit>().loginWithPIN(pin),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton.outline(
                      onTap: () => context.read<AuthCubit>().togglePinFallback(false),
                      title: 'BACK TO STANDARD CREDENTIALS',
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
