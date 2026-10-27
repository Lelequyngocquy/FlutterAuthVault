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
  bool _obscurePassword = true;
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
              LiveData.showSuccess(msg: 'Xác thực danh tính thành công');
              context.go(RouterPath.dashboard);
            } else if (state.status == BlocStatus.error && state.message != null) {
              LiveData.showError(msg: state.message!);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Dimen.spaceXl, vertical: Dimen.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: StatusPill(label: 'BẢO MẬT PHẦN CỨNG', color: UIColors.primary, maxLines: 2),
                      ),
                      const SizedBox(width: 8),
                      if (_integrityReport != null)
                        Flexible(
                          child: StatusPill(
                            label: _integrityReport!.isSecure ? 'THIẾT BỊ AN TOÀN' : 'CHẾ ĐỘ MÔ PHỎNG',
                            color: _integrityReport!.isSecure ? UIColors.primary : UIColors.warning,
                            maxLines: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppText.eyebrow('HỆ THỐNG XÁC THỰC ZERO-TRUST', maxLines: 2),
                  const SizedBox(height: 8),
                  AppText.bold('AuthVault Security Hub', fontSize: 24, maxLines: 2),
                  const SizedBox(height: 6),
                  AppText.regular(
                    'Cổng bảo vệ tài sản số với sinh trắc học mật mã & bàn phím xáo trộn',
                    color: UIColors.mute,
                    fontSize: 13,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: UIColors.canvasSoft,
                      borderRadius: BorderRadius.circular(Dimen.radiusSm),
                      border: Border.all(color: UIColors.hairline, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: UIColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppText.regular(
                            'Tài khoản thử nghiệm: admin / admin123 (Mã PIN: 123456)',
                            color: UIColors.body,
                            fontSize: 12,
                            maxLines: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!state.isPinFallbackMode) ...[
                    TerminalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTextField(
                            controller: _usernameCtrl,
                            label: 'TÊN ĐĂNG NHẬP (USER ID)',
                            hint: 'Nhập tên tài khoản (admin)',
                            prefixIcon: const Icon(Icons.person_outline, color: UIColors.mute, size: 18),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'MẬT KHẨU BẢO MẬT',
                            hint: 'Nhập mật khẩu (admin123)',
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline, color: UIColors.mute, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: UIColors.mute,
                                size: 18,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 20),
                          AppButton.primary(
                            onTap: () => context.read<AuthCubit>().loginWithPassword(
                              _usernameCtrl.text.trim(),
                              _passwordCtrl.text.trim(),
                            ),
                            loading: state.isLoading,
                            icon: Icons.login,
                            title: 'ĐĂNG NHẬP BẰNG MẬT KHẨU',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton.outline(
                      onTap: () => context.read<AuthCubit>().loginWithBiometrics(),
                      loading: state.isLoading,
                      icon: Icons.fingerprint,
                      title: 'XÁC THỰC BẰNG VÂN TAY (CHALLENGE-RESPONSE)',
                    ),
                    const SizedBox(height: 12),
                    AppButton.outline(
                      onTap: () => context.read<AuthCubit>().togglePinFallback(true),
                      icon: Icons.dialpad,
                      title: 'CHUYỂN SANG BÀN PHÍM PIN XÁO TRỘN',
                    ),
                  ] else ...[
                    TerminalCard(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: AppText.eyebrow('BÀN PHÍM CHỐNG QUAY LÉN', maxLines: 2),
                              ),
                              const SizedBox(width: 8),
                              const StatusPill(label: 'XÁO TRỘN 0-9', color: UIColors.primary),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AppText.regular(
                            'Vị trí các con số được đảo lộn ngẫu nhiên mỗi lần chạm để ngăn nhìn trộm mã PIN',
                            color: UIColors.mute,
                            fontSize: 12,
                            maxLines: 3,
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
                      icon: Icons.keyboard_return,
                      title: 'QUAY LẠI ĐĂNG NHẬP MẬT KHẨU',
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
