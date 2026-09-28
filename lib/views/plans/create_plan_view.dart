import 'package:flutter/material.dart';
import 'package:plansync/models/user.dart';
import 'package:plansync/utils/date_format.dart';
import 'package:plansync/viewmodels/plans/create_plan_viewmodel.dart';
import 'package:plansync/views/plans/plan_detail_view.dart';
import 'package:provider/provider.dart';

class CreatePlanView extends StatelessWidget {
  const CreatePlanView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CreatePlanViewModel(context.read<User>().id),
      child: const _CreatePlanForm(),
    );
  }
}

class _CreatePlanForm extends StatelessWidget {
  const _CreatePlanForm();

  Future<void> _pickDate(BuildContext context, CreatePlanViewModel vm) async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: vm.date ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (day == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(vm.date ?? now),
    );
    if (time == null) return;
    vm.setDate(DateTime(day.year, day.month, day.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreatePlanViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Plan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('PLAN NAME'),
          TextField(
            controller: vm.nameController,
            decoration: const InputDecoration(hintText: 'e.g. Friday dinner'),
          ),
          const SizedBox(height: 16),
          const Text('DATE'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(
              vm.date == null
                  ? 'Pick date & time'
                  : '${formatShortDate(vm.date!)} · ${formatTime(TimeOfDay.fromDateTime(vm.date!))}',
            ),
            onTap: () => _pickDate(context, vm),
          ),
          if (vm.errorMessage != null)
            Text(
              vm.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: vm.isLoading
                ? null
                : () async {
                    final plan = await vm.save();
                    if (plan != null && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanDetailView(plan: plan),
                        ),
                      );
                    }
                  },
            child: const Text('Create Plan'),
          ),
        ],
      ),
    );
  }
}
