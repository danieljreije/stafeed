import '../../../tool/daily_summary/daily_summary.dart';

/// An in-memory GitHub for the daily summary tests. It answers the same
/// REST paths the real one does (with paging), and records every write.
class FakeGitHub implements GitHubApi {
  /// Sub-issues per spec number, in sub-issue order.
  final Map<int, List<Map<String, Object?>>> subIssues = {31: [], 1: []};
  final List<Map<String, Object?>> pulls = [];
  final List<Map<String, Object?>> failedRuns = [];

  /// Repo-wide issue events, newest first (as GitHub returns them).
  final List<Map<String, Object?>> issueEvents = [];
  final Map<int, List<Map<String, Object?>>> comments = {};

  final List<String> reads = [];
  final List<({int issue, String body})> postedComments = [];

  @override
  Future<Object?> get(String path) async {
    reads.add(path);
    final uri = Uri.parse(path);
    if (!uri.path.startsWith('$repo/')) {
      throw StateError('Unexpected path: $path');
    }
    final rest = uri.path.substring(repo.length + 1);
    final parts = rest.split('/');

    if (rest == 'pulls') return _page(pulls, uri);
    if (rest == 'issues/events') return _page(issueEvents, uri);
    if (rest == 'actions/runs') {
      // Like GitHub: `status` picks one conclusion, `created=>X` only
      // returns runs that started after X.
      final status = uri.queryParameters['status'];
      final created = uri.queryParameters['created'];
      final after = created != null && created.startsWith('>')
          ? DateTime.parse(created.substring(1))
          : null;
      final runs = [
        for (final run in failedRuns)
          if (run['conclusion'] == status &&
              (after == null ||
                  DateTime.parse('${run['created_at']}').isAfter(after)))
            run,
      ];
      return {'total_count': runs.length, 'workflow_runs': _page(runs, uri)};
    }
    if (parts.length == 3 && parts[0] == 'issues') {
      final number = int.parse(parts[1]);
      if (parts[2] == 'sub_issues') return subIssues[number] ?? [];
      if (parts[2] == 'comments') return _page(comments[number] ?? [], uri);
    }
    throw StateError('Unexpected path: $path');
  }

  @override
  Future<void> postComment(int issue, String body) async {
    postedComments.add((issue: issue, body: body));
  }

  List<Object?> _page(List<Map<String, Object?>> all, Uri uri) {
    final perPage = int.parse(uri.queryParameters['per_page'] ?? '30');
    final page = int.parse(uri.queryParameters['page'] ?? '1');
    return all.skip((page - 1) * perPage).take(perPage).toList();
  }
}

/// A ticket as the sub-issues endpoint returns it.
Map<String, Object?> ticket(
  int number,
  String title, {
  String state = 'open',
  List<String> labels = const ['ready-for-agent'],
  List<String> assignees = const [],
  int blockedBy = 0,
}) => {
  'number': number,
  'title': title,
  'state': state,
  'labels': [
    for (final label in labels) {'name': label},
  ],
  'assignees': [
    for (final login in assignees) {'login': login},
  ],
  'issue_dependencies_summary': {'blocked_by': blockedBy},
};

/// A pull request as the pulls endpoint returns it.
Map<String, Object?> pull(
  int number,
  String title, {
  required String branch,
  String state = 'closed',
  String? mergedAt,
  String body = '',
}) => {
  'number': number,
  'title': title,
  'state': state,
  'merged_at': mergedAt,
  'body': body,
  'head': {'ref': branch},
  'html_url': 'https://github.com/danieljreije/stafeed/pull/$number',
};

/// A failed workflow run as the Actions runs endpoint returns it.
Map<String, Object?> failedRun(
  int id,
  String workflow, {
  required String branch,
  required String createdAt,
  String? finishedAt,
  String conclusion = 'failure',
}) => {
  'id': id,
  'name': workflow,
  'head_branch': branch,
  'conclusion': conclusion,
  'created_at': createdAt,
  'updated_at': finishedAt ?? createdAt,
  'html_url': 'https://github.com/danieljreije/stafeed/actions/runs/$id',
};

/// A "labeled" issue event as the repo-wide issue events endpoint returns it.
/// The embedded issue shows the issue as it is now.
Map<String, Object?> labeled(
  String label, {
  required int issue,
  required String title,
  required String at,
  String state = 'open',
  List<String>? labelsNow,
  bool isPullRequest = false,
}) => {
  'event': 'labeled',
  'created_at': at,
  'label': {'name': label},
  'issue': {
    'number': issue,
    'title': title,
    'state': state,
    'labels': [
      for (final name in labelsNow ?? [label]) {'name': name},
    ],
    'pull_request': ?(isPullRequest ? <String, Object?>{} : null),
  },
};

/// An issue comment.
Map<String, Object?> comment(String body, {required String at}) => {
  'body': body,
  'created_at': at,
};
