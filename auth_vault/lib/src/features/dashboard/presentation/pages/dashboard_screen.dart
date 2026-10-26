import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/constants/colors.dart';
import '../../../../common/constants/dimen.dart';
import '../../../../core/domain/bloc_status.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadVaultItems();
  }
  @override
  Widget build(BuildContext context) {
    final authUser = context.watch<AuthCubit>().state.user;
    return Scaffold(
      backgroundColor: UIColors.canvas,
      appBar: AppBar(
        backgroundColor: UIColors.canvas,
        elevation: 0,
        title: AppText.mono('AUTHVAULT // HUB', color: UIColors.inkStrong),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: UIColors.error, size: 20),
            onPressed: () async {
              await context.read<AuthCubit>().logout();
              if (context.mounted) context.go(RouterPath.login);
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
                padding: const EdgeInsets.all(Dimen.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TerminalCard(
                      highlighted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText.eyebrow('ACTIVE SESSION'),
                              const StatusPill(label: 'TOKEN TTL: 30s', color: UIColors.primary),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText.mono(authUser?.username ?? 'admin', fontSize: 16, color: UIColors.inkStrong),
                                    const SizedBox(height: 2),
                                    AppText.regular('ROLE: ${authUser?.role ?? "SECURITY_OFFICER"}', color: UIColors.mute, fontSize: 12),
                                  ],
                                ),
                              ),
                              const StatusPill(label: 'ENCRYPTED', color: UIColors.primary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TerminalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.eyebrow('TOKEN REFRESH MUTEX CONCURRENCY TEST'),
                          const SizedBox(height: 6),
                          AppText.regular(
                            'Triggers 5 parallel requests when token expires. Verifies only 1 refresh call is executed, queueing and replaying all 5 cleanly.',
                            color: UIColors.mute,
                            fontSize: 12,
                          ),
                          const SizedBox(height: 16),
                          AppButton.primary(
                            onTap: () => context.read<DashboardCubit>().triggerConcurrent401Test(),
                            loading: state.isTestingConcurrency,
                            title: 'RUN 5 CONCURRENT REQUESTS (TEST MUTEX)',
                          ),
                          if (state.executionLogs.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(Dimen.spaceMd),
                              decoration: BoxDecoration(
                                color: UIColors.canvasSoft,
                                borderRadius: BorderRadius.circular(Dimen.radiusSm),
                                border: Border.all(color: UIColors.hairline, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: state.executionLogs.map((log) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: AppText.mono(log, fontSize: 11, color: UIColors.primary),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppText.eyebrow('PROTECTED FINTECH ASSETS'),
                        AppText.mono('${state.items.length} ITEMS', color: UIColors.mute, fontSize: 12),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.status == BlocStatus.loading && state.items.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: UIColors.primary),
                      ))
                    else
                      ...state.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TerminalCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: AppText.semiBold(item.title, fontSize: 14, color: UIColors.inkStrong),
                                    ),
                                    StatusPill(label: item.securityLevel.split('_').first, color: UIColors.primary),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                AppText.mono(item.secretSnippet, color: UIColors.primarySoft, fontSize: 12),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppText.eyebrow(item.category),
                                    AppText.mono(
                                      'ACCESSED: ${item.lastAccessed.hour}:${item.lastAccessed.minute.toString().padLeft(2, '0')}',
                                      color: UIColors.mute,
                                      fontSize: 10,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
