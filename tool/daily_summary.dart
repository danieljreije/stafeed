// Posts the daily summary on spec #1 (ticket #43). Run once a day by
// `.github/workflows/daily-summary.yml`.
//
//   dart run tool/daily_summary.dart          prints the summary, posts nothing
//   dart run tool/daily_summary.dart --post   posts it as one comment on #1
//
// It talks to GitHub through the `gh` CLI, so it uses whatever login `gh`
// has (in CI: the workflow's token). Set GH_EXE when `gh` is not on PATH.
import 'dart:convert';
import 'dart:io';

import 'daily_summary/daily_summary.dart';

Future<void> main(List<String> args) async {
  final unknown = args.where((arg) => arg != '--post').toList();
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown argument: ${unknown.join(' ')}');
    stderr.writeln('Usage: dart run tool/daily_summary.dart [--post]');
    exitCode = 64;
    return;
  }
  final post = args.contains('--post');

  final body = await runDailySummary(
    GhCli(Platform.environment['GH_EXE'] ?? 'gh'),
    now: DateTime.now().toUtc(),
    post: post,
  );
  stdout.writeln(body);
  stdout.writeln();
  stdout.writeln(
    post
        ? 'Posted on #$summaryIssue.'
        : 'Trial run: nothing was posted. Pass --post to post it.',
  );
}

/// GitHub through the `gh` CLI.
class GhCli implements GitHubApi {
  GhCli(this.executable);

  final String executable;

  @override
  Future<Object?> get(String path) async => jsonDecode(await _gh([path]));

  @override
  Future<void> postComment(int issue, String body) =>
      _gh(['$repo/issues/$issue/comments', '-f', 'body=$body']);

  Future<String> _gh(List<String> args) async {
    final result = await Process.run(
      executable,
      ['api', ...args],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        executable,
        ['api', args.first],
        '${result.stderr}'.trim(),
        result.exitCode,
      );
    }
    return result.stdout as String;
  }
}
