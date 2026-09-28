import 'package:flutter/material.dart';
import 'package:plansync/models/group.dart';
import 'package:plansync/models/group_invitation.dart';
import 'package:plansync/theme/app_theme.dart';
import 'package:plansync/viewmodels/crew/group_viewmodel.dart';
import 'package:plansync/views/widgets/crew_group_card.dart';
import 'package:provider/provider.dart';

class GroupInviteView extends StatelessWidget {
  const GroupInviteView({super.key});

  Future<void> _accept(
    BuildContext context,
    CrewViewmodel vm,
    GroupInvitation invitation,
    Group group,
  ) async {
    vm.clearError();
    await vm.acceptInvitation(invitation);
    if (!context.mounted) return;
    if (vm.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.error!)));
      return;
    }
    Navigator.of(context).pop(group);
  }

  Future<void> _deny(
    BuildContext context,
    CrewViewmodel vm,
    GroupInvitation invitation,
  ) async {
    vm.clearError();
    await vm.denyInvitation(invitation);
    if (!context.mounted || vm.error == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(vm.error!)));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CrewViewmodel>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ColoredBox(
      color: const Color(0xFFFAFAFA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: SizedBox(
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Group Invite',
                      style: text.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BackButton(
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.greyLight),
          Expanded(
            child: vm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vm.error != null
                ? Center(child: Text(vm.error!))
                : vm.invitations.isEmpty
                ? Center(
                    child: Text(
                      'No group invitations',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(34, 18, 34, 12),
                    itemCount: vm.invitations.length,
                    itemBuilder: (context, index) {
                      final invitation = vm.invitations[index];
                      final group = vm.groupForInvitation(invitation);
                      if (group == null) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final memberCount = vm.memberCountFor(group.id);
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == vm.invitations.length - 1 ? 0 : 28,
                        ),
                        child: CrewGroupCard(
                          name: group.name,
                          memberCount: memberCount,
                          avatarCount: memberCount.clamp(0, 3),
                          overflowCount: memberCount > 3
                              ? memberCount - 3
                              : null,
                          onAccept: () =>
                              _accept(context, vm, invitation, group),
                          onDeny: () => _deny(context, vm, invitation),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF0EC),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_back, size: 20, color: AppTheme.black),
        ),
      ),
    );
  }
}
