/// The daily summary on spec #1 (ticket #43): one comment a day that tells
/// the owner what merged, what failed, what was handed back to them as
/// `ready-for-human`, and which ticket the orchestrator takes next.
///
/// Everything here only reads from GitHub, except the one comment it posts.
library;

/// The repository the summary reads, as a REST path prefix.
const repo = 'repos/danieljreije/stafeed';

/// The spec the summary is posted on.
const summaryIssue = 1;

/// Specs in the order the orchestrator works through them
/// (`docs/agents/orchestrator-run.md`, step 1).
const specOrder = [31, 1];

/// Hidden marker at the top of every summary comment. It records the moment
/// the summary covers up to; the next run finds the last summary by it and
/// reports what happened after that moment.
String summaryMarker(DateTime until) =>
    '$_markerStart${until.toUtc().toIso8601String()} -->';

const _markerStart = '<!-- stafeed-daily-summary until=';

/// The line every orchestrator PR carries in its body.
const _orchestratorPrLine = 'Opened by the Stafeed orchestrator';

/// How the orchestrator starts its comment when it hands a ticket back.
const _gaveUpPrefix = 'Stafeed orchestrator gave up:';

/// The part of GitHub the summary needs: reading, and posting one comment.
abstract interface class GitHubApi {
  /// GETs a REST path such as `repos/<owner>/<repo>/pulls?state=all` and
  /// returns the decoded JSON.
  Future<Object?> get(String path);

  /// Posts a comment on an issue. The summary's only write.
  Future<void> postComment(int issue, String body);
}

/// Builds the summary of everything after the last summary (or the last 24
/// hours when there is none yet) up to [now] and, when [post] is true, posts
/// it as one comment on spec #1. Returns the comment text either way.
Future<String> runDailySummary(
  GitHubApi github, {
  required DateTime now,
  required bool post,
}) async {
  final since =
      await _lastSummaryTime(github) ??
      now.toUtc().subtract(const Duration(days: 1));
  final window = _Window(since, now.toUtc());
  final pulls = await _allPages(
    github,
    '$repo/pulls?state=all&sort=updated&direction=desc',
  );

  final merged = _mergedIn(window, pulls);
  final failed = await _failedIn(window, github, pulls);
  final handedBack = await _handedBackIn(window, github);
  final next = await _nextUp(github, pulls);

  final marker = summaryMarker(now);
  final String body;
  if (merged.isEmpty && failed.isEmpty && handedBack.isEmpty) {
    body = '$marker\nNo activity since ${_stamp(since)}. Next: $next';
  } else {
    String section(String heading, List<String> lines) =>
        '**$heading**\n${(lines.isEmpty ? ['none'] : lines).map((line) => '- $line').join('\n')}';
    body = [
      '$marker\n## Daily summary, ${_stamp(now).substring(0, 10)}',
      'Since ${_stamp(since)}.',
      section('Merged', merged),
      section('Failed', failed),
      section('Handed to you (`ready-for-human`)', handedBack),
      section('Next', [next]),
    ].join('\n\n');
  }

  if (post) await github.postComment(summaryIssue, body);
  return body;
}

/// The moment the last summary covers up to, or null when there is none yet.
Future<DateTime?> _lastSummaryTime(GitHubApi github) async {
  final comments = await _allPages(
    github,
    '$repo/issues/$summaryIssue/comments',
  );
  DateTime? last;
  for (final comment in comments) {
    final body = '${comment['body'] ?? ''}';
    if (!body.startsWith(_markerStart)) continue;
    final until = _time(body.substring(_markerStart.length).split(' ').first);
    if (until != null && (last == null || until.isAfter(last))) last = until;
  }
  return last;
}

/// PRs merged in [window], newest first.
List<String> _mergedIn(_Window window, List<_Json> pulls) {
  final merged = _newestFirst(window, pulls, (pr) => pr['merged_at']);
  return [for (final pr in merged) '#${pr['number']} ${pr['title']}'];
}

/// Workflow runs that failed in [window], one line per workflow and PR (or
/// branch, when the branch has no PR), newest first.
Future<List<String>> _failedIn(
  _Window window,
  GitHubApi github,
  List<_Json> pulls,
) async {
  // A run counts when it finished, so also ask for runs that started up to
  // a day before the window (no run lasts longer than that).
  final created = Uri.encodeQueryComponent(
    '>${window.since.subtract(const Duration(days: 1)).toIso8601String()}',
  );
  final all = <_Json>[];
  for (final status in const ['failure', 'timed_out', 'startup_failure']) {
    for (var page = 1; ; page++) {
      final answer = await github.get(
        '$repo/actions/runs?status=$status&created=$created'
        '&per_page=100&page=$page',
      ) as _Json;
      final runs = (answer['workflow_runs'] as List).cast<_Json>();
      all.addAll(runs);
      if (runs.length < 100) break;
    }
  }
  final runs = _newestFirst(
    window,
    all,
    (run) => run['updated_at'] ?? run['created_at'],
  );

  final groups = <String, List<_Json>>{};
  for (final run in runs) {
    final branch = '${run['head_branch']}';
    final pr = pulls.where((pr) => _branch(pr) == branch).firstOrNull;
    final where = pr == null
        ? 'on `$branch`'
        : 'on PR #${pr['number']} ${pr['title']}';
    groups.putIfAbsent('${run['name']} $where', () => []).add(run);
  }
  return [
    for (final MapEntry(key: what, value: runs) in groups.entries)
      '$what: ${runs.length} failed ${runs.length == 1 ? 'run' : 'runs'} '
          '([latest](${runs.first['html_url']}))',
  ];
}

/// Tickets labelled `ready-for-human` in [window] that are still open and
/// still carry the label, newest first.
Future<List<String>> _handedBackIn(_Window window, GitHubApi github) async {
  final tickets = <int, String>{};
  // Events come newest first: stop at the first one from before the window.
  // 20 pages is 2,000 events, far more than the tracker sees between runs.
  pages:
  for (var page = 1; page <= 20; page++) {
    final events =
        await github.get('$repo/issues/events?per_page=100&page=$page') as List;
    for (final event in events.cast<_Json>()) {
      final at = _time(event['created_at']);
      if (at != null && !at.isAfter(window.since)) break pages;
      final issue = event['issue'] as _Json?;
      if (!window.contains(at) ||
          event['event'] != 'labeled' ||
          (event['label'] as _Json?)?['name'] != 'ready-for-human' ||
          issue == null ||
          issue['pull_request'] != null ||
          issue['state'] != 'open' ||
          !_labels(issue).contains('ready-for-human')) {
        continue;
      }
      tickets.putIfAbsent(issue['number'] as int, () => '${issue['title']}');
    }
    if (events.length < 100) break;
  }

  final lines = <String>[];
  for (final MapEntry(key: number, value: title) in tickets.entries) {
    final comments = await _allPages(github, '$repo/issues/$number/comments');
    final gaveUp = comments.any(
      (comment) =>
          '${comment['body'] ?? ''}'.startsWith(_gaveUpPrefix) &&
          window.contains(_time(comment['created_at'])),
    );
    lines.add('#$number $title${gaveUp ? ' (the orchestrator gave up)' : ''}');
  }
  return lines;
}

/// What the orchestrator does on its next run: the PR it continues, or the
/// first ticket in spec order that passes every check of the run prompt.
Future<String> _nextUp(GitHubApi github, List<_Json> pulls) async {
  for (final pr in pulls) {
    if (pr['state'] == 'open' &&
        '${pr['body'] ?? ''}'.contains(_orchestratorPrLine)) {
      return 'the orchestrator continues PR #${pr['number']} ${pr['title']}';
    }
  }

  for (final spec in specOrder) {
    final tickets = await github.get(
      '$repo/issues/$spec/sub_issues?per_page=100',
    );
    for (final ticket in (tickets as List).cast<_Json>()) {
      if (_isNext(ticket, pulls)) {
        return '#${ticket['number']} ${ticket['title']}';
      }
    }
  }
  return 'nothing. No ticket is open, `ready-for-agent`, unassigned and '
      'unblocked.';
}

bool _isNext(_Json ticket, List<_Json> pulls) {
  final labels = _labels(ticket);
  if (ticket['state'] != 'open') return false;
  if (labels.contains('ready-for-human')) return false;
  if (!labels.contains('ready-for-agent')) return false;
  if (pulls.any((pr) => _belongsTo(pr, ticket['number'] as int))) return false;
  if ((ticket['assignees'] as List? ?? const []).isNotEmpty) return false;
  final blockedBy =
      (ticket['issue_dependencies_summary'] as _Json?)?['blocked_by'];
  return blockedBy == null || blockedBy == 0;
}

/// A merged or open PR belongs to ticket N when its branch contains
/// `ticket-N-` or its title contains `(#N)`. Closed-unmerged PRs don't count.
bool _belongsTo(_Json pr, int ticket) {
  final live = pr['state'] == 'open' || pr['merged_at'] != null;
  if (!live) return false;
  return _branch(pr).contains('ticket-$ticket-') ||
      '${pr['title']}'.contains('(#$ticket)');
}

String _branch(_Json pr) => '${(pr['head'] as _Json?)?['ref'] ?? ''}';

Set<String> _labels(_Json issue) => {
  for (final label in (issue['labels'] as List? ?? const []))
    '${(label as _Json)['name']}',
};

/// Reads every page of a list endpoint.
Future<List<_Json>> _allPages(GitHubApi github, String path) async {
  final all = <_Json>[];
  for (var page = 1; ; page++) {
    final separator = path.contains('?') ? '&' : '?';
    final items =
        await github.get('$path${separator}per_page=100&page=$page') as List;
    all.addAll(items.cast<_Json>());
    if (items.length < 100) return all;
  }
}

/// The stretch of time one summary covers: after [since], up to [until].
class _Window {
  const _Window(this.since, this.until);

  final DateTime since;
  final DateTime until;

  bool contains(DateTime? time) =>
      time != null && time.isAfter(since) && !time.isAfter(until);
}

/// The [items] whose time (an ISO string picked by [timeOf]) is in [window],
/// newest first.
List<_Json> _newestFirst(
  _Window window,
  List<_Json> items,
  Object? Function(_Json item) timeOf,
) {
  final timed = [
    for (final item in items)
      if (_time(timeOf(item)) case final time? when window.contains(time))
        (time: time, item: item),
  ]..sort((a, b) => b.time.compareTo(a.time));
  return [for (final entry in timed) entry.item];
}

DateTime? _time(Object? iso) => iso is String ? DateTime.tryParse(iso) : null;

/// `2026-11-13 06:00 UTC`
String _stamp(DateTime time) {
  final t = time.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} '
      '${two(t.hour)}:${two(t.minute)} UTC';
}

typedef _Json = Map<String, Object?>;
