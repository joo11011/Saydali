import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/debt_cubit.dart';
import 'package:smart_pharmacy_system/business_logic/cubits/debt_state.dart';
import 'package:smart_pharmacy_system/core/constants/app_colors.dart';
import 'package:smart_pharmacy_system/data/models/debt.dart';

class DebtsView extends StatefulWidget {
  const DebtsView({super.key});

  @override
  State<DebtsView> createState() => _DebtsViewState();
}

class _DebtsViewState extends State<DebtsView> {
  @override
  void initState() {
    super.initState();
    context.read<DebtCubit>().loadDebts();
  }

  void _showAddDebtDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دين جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم العميل'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                final debt = Debt(
                  id: DateTime.now().toString(),
                  customerName: nameController.text,
                  amount: double.tryParse(amountController.text) ?? 0.0,
                  date: DateTime.now(),
                  notes: notesController.text,
                );
                context.read<DebtCubit>().addDebt(debt);
                Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showPayDialog(Debt debt) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('سداد جزء من دين: ${debt.customerName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المتبقي: ${debt.remainingAmount} ج.م'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'مبلغ السداد'),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                context.read<DebtCubit>().payDebt(debt.id, amount);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('سداد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دفتر الديون (الشكك)')),
      body: BlocBuilder<DebtCubit, DebtState>(
        builder: (context, state) {
          if (state is DebtLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DebtLoaded) {
            if (state.debts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد ديون مسجلة',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColor.errorColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColor.errorColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'إجمالي الديون: ${state.totalDebt.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColor.errorColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.debts.length,
                    itemBuilder: (context, index) {
                      final debt = state.debts[index];
                      // Hide fully paid debts from main list? Or keep them? Let's keep them but dim them.
                      final isPaid = debt.remainingAmount <= 0;

                      return Card(
                        color: isPaid ? Colors.grey.withOpacity(0.1) : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPaid ? Colors.green : Colors.red,
                            child: Icon(
                              isPaid ? Icons.check : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            debt.customerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المبلغ الكلي: ${debt.amount} | مدفوع: ${debt.paidAmount}',
                              ),
                              if (debt.notes.isNotEmpty)
                                Text(
                                  'ملاحظة: ${debt.notes}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              Text(
                                DateFormat('yyyy-MM-dd').format(debt.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${debt.remainingAmount.toStringAsFixed(0)} ج.م',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isPaid
                                      ? Colors.green
                                      : AppColor.errorColor,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!isPaid) _showPayDialog(debt);
                          },
                          onLongPress: () {
                            // Option to delete
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('حذف السجل'),
                                content: const Text(
                                  'هل تريد حذف هذا الدين نهائياً؟',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('إلغاء'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<DebtCubit>().deleteDebt(
                                        debt.id,
                                      );
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColor.errorColor,
                                    ),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('حدث خطأ'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addDebt',
        onPressed: _showAddDebtDialog,
        icon: const Icon(Icons.add),
        label: const Text('دين جديد'),
        backgroundColor: AppColor.errorColor,
      ),
    );
  }
}
