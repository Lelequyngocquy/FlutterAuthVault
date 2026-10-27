import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/dimen.dart';
import '../../../../core/domain/bloc_status.dart';
import '../../../../core/infrastructure/datasources/local/live_data.dart';
import '../../../../core/infrastructure/security/app_lifecycle_privacy_observer.dart';
import '../../../../core/presentation/widgets/button.dart';
import '../../../../core/presentation/widgets/status_pill.dart';
import '../../../../core/presentation/widgets/terminal_card.dart';
import '../../../../core/presentation/widgets/text.dart';
import '../../../../shared/router/router_key_manager.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../cubits/dashboard_cubit.dart';
import '../cubits/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _activeTab = 0;
  int _remainingSeconds = 120;
  Timer? _countdownTimer;
  final Set<String> _revealedSecrets = {};
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadVaultItems();
    _startCountdown();
  }
  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }
  void _resetCountdown() {
    setState(() => _remainingSeconds = 120);
    _startCountdown();
    LiveData.showSuccess(msg: 'Đã đặt lại đồng hồ tự khóa về 120 giây');
  }
  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthCubit>().state.user;
    return Scaffold(
      backgroundColor: UIColors.canvas,
      appBar: AppBar(
        backgroundColor: UIColors.canvas,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: UIColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: AppText.bold(
                'AuthVault Security Hub',
                fontSize: 16,
                maxLines: 2,
                color: UIColors.inkStrong,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất an toàn',
            icon: const Icon(Icons.logout, color: UIColors.error, size: 20),
            onPressed: () async {
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                LiveData.showSuccess(msg: 'Đã đăng xuất phiên làm việc');
                context.go(RouterPath.login);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadVaultItems(),
              color: UIColors.primary,
              backgroundColor: UIColors.canvasSoft,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: Dimen.spaceLg, vertical: Dimen.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSessionHeaderCard(authUser),
                    const SizedBox(height: 16),
                    _buildTabSwitcher(),
                    const SizedBox(height: 18),
                    if (_activeTab == 0)
                      _buildSecurityLabTab(state)
                    else
                      _buildVaultAssetsTab(state),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  Widget _buildSessionHeaderCard(dynamic authUser) {
    return TerminalCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText.eyebrow('PHIÊN LÀM VIỆC AN TOÀN', maxLines: 2),
              ),
              const SizedBox(width: 8),
              const StatusPill(label: 'XOAY VÒNG TOKEN: 30S', color: UIColors.primary),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: UIColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: UIColors.primary, width: 1),
                ),
                child: const Icon(Icons.verified_user_outlined, color: UIColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.semiBold(
                      authUser?.username ?? 'Quản trị viên (admin)',
                      fontSize: 15,
                      maxLines: 3,
                      color: UIColors.inkStrong,
                    ),
                    const SizedBox(height: 2),
                    AppText.regular(
                      'Vai trò: ${authUser?.role ?? "QUẢN TRỊ VIÊN BẢO MẬT"}',
                      color: UIColors.mute,
                      fontSize: 12,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusPill(label: 'ĐÃ MÃ HÓA', color: UIColors.primary, fill: true),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildTabSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: UIColors.canvasSoft,
        borderRadius: BorderRadius.circular(Dimen.radiusSm),
        border: Border.all(color: UIColors.hairline, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 0),
              borderRadius: BorderRadius.circular(Dimen.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? UIColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(Dimen.radiusSm),
                  border: _activeTab == 0 ? Border.all(color: UIColors.primary, width: 1) : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: _activeTab == 0 ? UIColors.primary : UIColors.mute,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AppText.semiBold(
                        'PHÒNG THÍ NGHIỆM',
                        fontSize: 12,
                        maxLines: 2,
                        color: _activeTab == 0 ? UIColors.primary : UIColors.mute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _activeTab = 1),
              borderRadius: BorderRadius.circular(Dimen.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? UIColors.primary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(Dimen.radiusSm),
                  border: _activeTab == 1 ? Border.all(color: UIColors.primary, width: 1) : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: _activeTab == 1 ? UIColors.primary : UIColors.mute,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AppText.semiBold(
                        'KHO TÀI SẢN MẬT',
                        fontSize: 12,
                        maxLines: 2,
                        color: _activeTab == 1 ? UIColors.primary : UIColors.mute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSecurityLabTab(DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText.eyebrow('KIỂM THỬ 4 LỚP PHÒNG THỦ THỰC TẾ', maxLines: 2),
            ),
            const SizedBox(width: 8),
            const StatusPill(label: '4/4 HOẠT ĐỘNG', color: UIColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        _buildExperimentCard1(state),
        const SizedBox(height: 14),
        _buildExperimentCard2(),
        const SizedBox(height: 14),
        _buildExperimentCard3(),
        const SizedBox(height: 14),
        _buildExperimentCard4(),
      ],
    );
  }
  Widget _buildExperimentCard1(DashboardState state) {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.sync_alt, color: UIColors.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.semiBold(
                        'Thí nghiệm 1: Chống Đứt Phiên (Token Mutex)',
                        fontSize: 13,
                        maxLines: 3,
                        color: UIColors.inkStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusPill(label: 'TẢI ĐỒNG THỜI', color: UIColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          AppText.regular(
            'Mô phỏng tình huống token hết hạn nhưng bắn cùng lúc 5 request dữ liệu. Mutex sẽ xếp hàng và chỉ gửi đúng 1 lần đổi chìa khóa mới, sau đó tự động phát lại cả 5 request thành công 100%.',
            color: UIColors.mute,
            fontSize: 12,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          AppButton.primary(
            onTap: () => context.read<DashboardCubit>().triggerConcurrent401Test(),
            loading: state.isTestingConcurrency,
            icon: Icons.bolt,
            title: 'KÍCH HOẠT 5 REQUEST ĐỒNG THỜI',
          ),
          if (state.executionLogs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(Dimen.spaceMd),
              decoration: BoxDecoration(
                color: UIColors.canvasSoft,
                borderRadius: BorderRadius.circular(Dimen.radiusSm),
                border: Border.all(color: UIColors.hairline, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, color: UIColors.primary, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: AppText.mono(
                          'NHẬT KÝ THỰC THI (EXECUTION LOG)',
                          color: UIColors.primary,
                          fontSize: 11,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...state.executionLogs.map((log) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: AppText.mono(log, fontSize: 11, maxLines: 3, color: UIColors.ink),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildExperimentCard2() {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.blur_on, color: UIColors.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.semiBold(
                        'Thí nghiệm 2: Tấm Rèm Bảo Mật (Privacy Curtain)',
                        fontSize: 13,
                        maxLines: 3,
                        color: UIColors.inkStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusPill(label: 'CHỐNG CHỤP MÀN HÌNH', color: UIColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          AppText.regular(
            'Khi bạn bấm phím Đa nhiệm (Recent Apps) để chuyển qua ứng dụng khác, màn hình lập tức bị làm mờ để chống hệ điều hành Android lưu ảnh nhạy cảm vào bộ nhớ đệm.',
            color: UIColors.mute,
            fontSize: 12,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          AppButton.outline(
            onTap: () => PrivacyCurtainContainer.triggerPreview(duration: const Duration(seconds: 3)),
            icon: Icons.visibility_outlined,
            title: 'XEM THỬ TẤM RÈM BẢO VỆ (3 GIÂY)',
          ),
        ],
      ),
    );
  }
  Widget _buildExperimentCard3() {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.timer_outlined, color: UIColors.warning, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.semiBold(
                        'Thí nghiệm 3: Tự Động Khóa Khi Bỏ Quên Máy',
                        fontSize: 13,
                        maxLines: 3,
                        color: UIColors.inkStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: 'CÒN $_remainingSeconds GIÂY', color: UIColors.warning),
            ],
          ),
          const SizedBox(height: 8),
          AppText.regular(
            'Nếu bạn không chạm vào màn hình trong 120 giây (2 phút), app sẽ xóa sạch phiên làm việc và tự động văng về màn hình đăng nhập để chống kẻ gian cầm máy đọc trộm.',
            color: UIColors.mute,
            fontSize: 12,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _remainingSeconds / 120.0,
              backgroundColor: UIColors.canvasSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                _remainingSeconds < 30 ? UIColors.error : UIColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),
          AppButton.outline(
            onTap: _resetCountdown,
            icon: Icons.touch_app_outlined,
            title: 'CHẠM ĐỂ ĐẶT LẠI THỜI GIAN (RESET 120S)',
          ),
        ],
      ),
    );
  }
  Widget _buildExperimentCard4() {
    return TerminalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.dialpad, color: UIColors.primary, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText.semiBold(
                        'Thí nghiệm 4: Bàn Phím Số Xáo Trộn (Scrambled PIN)',
                        fontSize: 13,
                        maxLines: 3,
                        color: UIColors.inkStrong,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const StatusPill(label: 'CHỐNG QUAY LÉN', color: UIColors.primary),
            ],
          ),
          const SizedBox(height: 8),
          AppText.regular(
            'Vị trí các con số từ 0 đến 9 được xáo trộn ngẫu nhiên mỗi lần chạm để vô hiệu hóa camera quay lén hoặc kẻ gian đứng nhìn trộm vị trí bấm ngón tay trên màn hình.',
            color: UIColors.mute,
            fontSize: 12,
            maxLines: 4,
          ),
          const SizedBox(height: 14),
          AppButton.outline(
            onTap: () async {
              await context.read<AuthCubit>().logout();
              if (mounted) context.go(RouterPath.login);
            },
            icon: Icons.dialpad_outlined,
            title: 'QUAY LẠI MÀN HÌNH ĐĂNG NHẬP ĐỂ THỬ BÀN PHÍM',
          ),
        ],
      ),
    );
  }
  Widget _buildVaultAssetsTab(DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AppText.eyebrow('DANH MỤC TÀI SẢN MẬT TRONG VAULT', maxLines: 2),
            ),
            const SizedBox(width: 8),
            AppText.mono('${state.items.length} TÀI SẢN', color: UIColors.primary, fontSize: 12),
          ],
        ),
        const SizedBox(height: 12),
        if (state.status == BlocStatus.loading && state.items.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: UIColors.primary),
            ),
          )
        else
          ...state.items.map((item) {
            final isRevealed = _revealedSecrets.contains(item.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TerminalCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.key_outlined, color: UIColors.primary, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppText.semiBold(
                                  item.title,
                                  fontSize: 14,
                                  maxLines: 3,
                                  color: UIColors.inkStrong,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatusPill(label: 'TỐI MẬT', color: UIColors.primary),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: UIColors.canvasSoft,
                        borderRadius: BorderRadius.circular(Dimen.radiusSm),
                        border: Border.all(color: UIColors.hairline, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: AppText.mono(
                              isRevealed ? item.secretSnippet : '••••••••••••••••••••••••••••••••',
                              color: isRevealed ? UIColors.primarySoft : UIColors.mute,
                              fontSize: 12,
                              maxLines: 3,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isRevealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 16,
                              color: UIColors.mute,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isRevealed) {
                                  _revealedSecrets.remove(item.id);
                                } else {
                                  _revealedSecrets.add(item.id);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppText.eyebrow('LOẠI: ${item.category}', maxLines: 2),
                        ),
                        const SizedBox(width: 8),
                        AppText.mono(
                          'TRUY CẬP: ${item.lastAccessed.hour}:${item.lastAccessed.minute.toString().padLeft(2, '0')}',
                          color: UIColors.mute,
                          fontSize: 11,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
