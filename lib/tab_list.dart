import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'counseling_record_detail.dart';
import 'models/conuseling_record.dart';
import 'tab_add.dart';

enum RecordSortOrder { newest, oldest }

class RecordsListScreen extends StatefulWidget {
  const RecordsListScreen({super.key});

  @override
  State<RecordsListScreen> createState() => _RecordsListScreenState();
}

class _RecordsListScreenState extends State<RecordsListScreen> {
  RecordSortOrder _sortOrder = RecordSortOrder.newest;

  Future<void> _openEditScreen(
    BuildContext context,
    CounselingRecord record,
    int recordIndex,
  ) async {
    if (recordIndex < 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('編集対象の記録が見つかりませんでした')));
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('記録を編集')),
          body: CounselingRecordScreen(
            initialRecord: record,
            editingIndex: recordIndex,
            onSaved: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    CounselingRecord record,
    int recordIndex,
  ) async {
    if (recordIndex < 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('削除対象の記録が見つかりませんでした')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('記録を削除'),
        content: Text('「${record.clinic}」の記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await deleteCounselingRecordAt(recordIndex);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('削除しました')));
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $error')));
    }
  }

  @override
  void initState() {
    super.initState();
    initializeCounselingRecords();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder<List<CounselingRecord>>(
      valueListenable: counselingRecordsNotifier,
      builder: (context, records, _) {
        final sortedRecords = [...records]
          ..sort((a, b) {
            final comparison = a.date.compareTo(b.date);
            return _sortOrder == RecordSortOrder.newest
                ? -comparison
                : comparison;
          });

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'カウンセリング記録',
                                style: theme.textTheme.displaySmall,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '総件数 ${sortedRecords.length} 件',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD7E1F0)),
                      ),
                      child: _SortToggle(
                        currentValue: _sortOrder,
                        onChanged: (value) {
                          setState(() {
                            _sortOrder = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
              sliver: SliverList.separated(
                itemCount: sortedRecords.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final record = sortedRecords[index];
                  final recordIndex = records.indexOf(record);
                  return _RecordCard(
                    record: record,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CounselingRecordDetailScreen(
                            record: record,
                            recordIndex: recordIndex,
                          ),
                        ),
                      );
                    },
                    onEdit: () => _openEditScreen(context, record, recordIndex),
                    onDelete: () => _deleteRecord(context, record, recordIndex),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final CounselingRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(record.clinic, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          '${record.doctor}  •  ${record.date}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: Color(0xFF61708E),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(record.memo, style: theme.textTheme.bodyLarge,maxLines: 4,overflow: TextOverflow.ellipsis,),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(CupertinoIcons.pencil),
                      label: const Text('編集'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: const Color(0xFF24365F),
                        side: const BorderSide(color: Color(0xFFD2DFF0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onDelete,
                      icon: const Icon(CupertinoIcons.delete),
                      label: const Text('削除'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          235,
                          230,
                        ),
                        foregroundColor: const Color.fromARGB(255, 184, 53, 53),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SortToggle extends StatelessWidget {
  const _SortToggle({required this.currentValue, required this.onChanged});

  final RecordSortOrder currentValue;
  final ValueChanged<RecordSortOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SortToggleItem(
            label: '新しい順',
            isSelected: currentValue == RecordSortOrder.newest,
            onTap: () => onChanged(RecordSortOrder.newest),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SortToggleItem(
            label: '古い順',
            isSelected: currentValue == RecordSortOrder.oldest,
            onTap: () => onChanged(RecordSortOrder.oldest),
          ),
        ),
      ],
    );
  }
}

class _SortToggleItem extends StatelessWidget {
  const _SortToggleItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? const Color(0xFF5672D9) : Colors.transparent,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF5672D9).withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF24365F),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
