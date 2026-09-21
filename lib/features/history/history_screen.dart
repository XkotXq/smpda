import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/api/models/sm_operation.dart';
import '../../core/api/sm_operations_api.dart';
import '../../core/session/session_providers.dart';
import '../../core/utils/quantity.dart';
import '../../i18n/gen/strings.g.dart';

/// Which of the logged-in person's operations a history screen lists - the
/// value is the `operation` the server filters on (sm_operations).
enum HistoryKind {
  /// Materiały SM: what this person issued.
  issue,

  /// FRP module: the spools this person labeled with numbers.
  labeling,
}

/// The logged-in person's own operations of one kind, newest first, read from
/// the server: the latest [_pageSize] when the screen opens, then the next
/// [_pageSize] each time the list is scrolled to its end. "operator" is the
/// employee number every operation is logged under (see
/// AppSettings.operatorName).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key, required this.kind});

  final HistoryKind kind;

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

const _pageSize = 10;

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();
  final _rows = <SmOperation>[];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;

  bool get _hasMore => _rows.length < _total;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _operator => ref.read(appSettingsProvider).value?.operatorName ?? '';

  Future<void> _loadFirstPage() async {
    setState(() {
      _loading = true;
      _failed = false;
      _rows.clear();
      _total = 0;
    });
    try {
      final operator = _operator;
      if (operator.isNotEmpty) {
        final page = await _fetch(operator, 0);
        _rows.addAll(page.rows);
        _total = page.total;
      }
    } catch (_) {
      _failed = true;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    _fillIfNotScrollable();
  }

  Future<({List<SmOperation> rows, int total})> _fetch(String operator, int offset) {
    return ref
        .read(smOperationsApiProvider)
        .list(limit: _pageSize, offset: offset, operator: operator, operation: widget.kind.name);
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _fetch(_operator, _rows.length);
      // Something newer may have been logged since the first page - it shifts
      // every offset by one, so skip what's already listed.
      final known = _rows.map((r) => r.id).toSet();
      _rows.addAll(page.rows.where((r) => !known.contains(r.id)));
      _total = page.total;
    } catch (_) {
      // Keep what's shown; scrolling to the end again retries.
    }
    if (!mounted) return;
    setState(() => _loadingMore = false);
    _fillIfNotScrollable();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) _loadMore();
  }

  /// A short page may not fill the screen, so there'd be nothing to scroll -
  /// keep loading until it does (or there's nothing more).
  void _fillIfNotScrollable() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) _loadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final t = context.t;
    final operator = ref.watch(appSettingsProvider.select((s) => s.value?.operatorName ?? ''));
    final title = widget.kind == HistoryKind.issue ? t.history.issuesTitle : t.history.labelingsTitle;

    Widget body;
    if (_loading) {
      body = const Center(child: ShadProgress());
    } else if (_failed) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.operations.toastLoadFailed, style: theme.textTheme.muted, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ShadButton.outline(onPressed: _loadFirstPage, child: Text(t.frp.retry)),
            ],
          ),
        ),
      );
    } else if (_rows.isEmpty) {
      body = Center(
        child: Text(t.history.empty, style: theme.textTheme.muted, textAlign: TextAlign.center),
      );
    } else {
      body = ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // One extra row at the end while more is being fetched.
        itemCount: _rows.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => Container(height: 1, color: theme.colorScheme.border),
        itemBuilder: (context, index) => index < _rows.length
            ? _HistoryRow(entry: _rows[index], showBatch: widget.kind != HistoryKind.labeling)
            : const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: ShadProgress()),
      );
    }

    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
              ),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: () => context.canPop() ? context.pop() : null,
                      child: Icon(LucideIcons.arrowLeft, size: 18, semanticLabel: t.nav.back),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(title, style: theme.textTheme.h4)),
                    ShadButton.ghost(
                      size: ShadButtonSize.sm,
                      onPressed: _loadFirstPage,
                      child: Icon(LucideIcons.refreshCw, size: 18, semanticLabel: t.history.refresh),
                    ),
                  ],
                ),
              ),
            ),
            if (operator.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                child: Text('${t.history.employee}: $operator', style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.showBatch});

  final SmOperation entry;

  /// The labeling list leaves the batch out - only the issues list shows it.
  final bool showBatch;

  /// "2026-09-21 11:04" in the device's local time.
  static String _formatTime(String? iso) {
    final parsed = iso == null ? null : DateTime.tryParse(iso);
    if (parsed == null) return iso ?? '';
    final local = parsed.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} ${pad(local.hour)}:${pad(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final details = [
      if ((entry.unitId ?? '').isNotEmpty) entry.unitId!,
      if (showBatch && (entry.productBatch ?? '').isNotEmpty) entry.productBatch!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.itemName, style: theme.textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(entry.itemNo, style: theme.textTheme.muted.copyWith(fontSize: 13)),
                if (details.isNotEmpty) Text(details, style: theme.textTheme.muted.copyWith(fontSize: 12)),
                const SizedBox(height: 2),
                Text(_formatTime(entry.time), style: theme.textTheme.muted.copyWith(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trimQuantity(entry.quantity),
            style: theme.textTheme.p.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
