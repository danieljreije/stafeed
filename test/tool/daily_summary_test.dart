import 'package:flutter_test/flutter_test.dart';

import '../../tool/daily_summary/daily_summary.dart';
import 'support/fake_github.dart';

void main() {
  final now = DateTime.utc(2026, 11, 14, 6);
  late FakeGitHub github;

  setUp(() {
    github = FakeGitHub();
    github.subIssues[1] = [ticket(4, '03: Feed Item kinds & labels')];
  });

  Future<String> postedSummary() async {
    await runDailySummary(github, now: now);
    expect(github.postedComments, hasLength(1));
    expect(github.postedComments.single.issue, 1);
    return github.postedComments.single.body;
  }

  test('a quiet day posts one short "no activity" comment on spec #1 '
      'that still names the next ticket', () async {
    final body = await postedSummary();

    expect(body, contains('No activity since 2026-11-13 06:00 UTC.'));
    expect(body, contains('Next: #4 03: Feed Item kinds & labels'));
    expect(body, isNot(contains('Merged')));
  });

  group('next ticket', () {
    test('is the first ticket in spec order that is open, ready-for-agent, '
        'unassigned, unblocked and has no PR', () async {
      github.subIssues[31] = [
        ticket(32, 'CI gate', state: 'closed'),
        ticket(40, 'Owner runs the script', labels: ['ready-for-human']),
        ticket(42, 'Live links', blockedBy: 1),
        ticket(44, 'Not triaged yet', labels: ['needs-triage']),
        ticket(45, 'Someone is on it', assignees: ['danieljreije']),
        ticket(46, 'Already merged'),
        ticket(47, 'Being built'),
        ticket(48, 'Abandoned attempt, still to do'),
      ];
      github.pulls.addAll([
        pull(
          70,
          'Already merged (#46)',
          branch: 'some-branch',
          mergedAt: '2026-11-10T10:00:00Z',
        ),
        pull(71, 'Being built', branch: 'claude/ticket-47-x', state: 'open'),
        pull(72, 'Closed without merging (#48)', branch: 'claude/ticket-48-x'),
      ]);

      final body = await postedSummary();

      expect(body, contains('Next: #48 Abandoned attempt, still to do'));
    });

    test('is the open orchestrator PR when one is in flight', () async {
      github.pulls.add(
        pull(
          71,
          'Feed Item kinds & labels (#4)',
          branch: 'claude/ticket-4-kinds',
          state: 'open',
          body: 'Closes #4\n\nOpened by the Stafeed orchestrator',
        ),
      );

      final body = await postedSummary();

      expect(
        body,
        contains(
          'Next: the orchestrator continues PR #71 '
          'Feed Item kinds & labels (#4)',
        ),
      );
    });

    test('says so when no ticket is ready', () async {
      github.subIssues[1] = [
        ticket(5, 'Video prototype', labels: ['ready-for-human']),
      ];

      final body = await postedSummary();

      expect(body, contains('Next: nothing.'));
    });
  });

  group('a day with activity', () {
    setUp(() {
      github.pulls.addAll([
        pull(
          61,
          'Orchestrator is live (#41)',
          branch: 'claude/ticket-41-live-record',
          mergedAt: '2026-11-13T17:30:47Z',
        ),
        pull(
          56,
          'Reliable feed (#3)',
          branch: 'claude/ticket-3-reliable-feed',
          mergedAt: '2026-11-13T09:07:03Z',
        ),
        pull(
          52,
          'DO NOT MERGE: golden check proof (#35)',
          branch: 'claude/ticket-35-goldens-proof',
        ),
        pull(
          46,
          'CI gate (#32)',
          branch: 'claude/ticket-32-ci-gate',
          mergedAt: '2026-11-12T12:00:00Z',
        ),
      ]);
      github.failedRuns.addAll([
        failedRun(
          903,
          'Nightly Android check',
          branch: 'main',
          createdAt: '2026-11-14T03:00:10Z',
        ),
        failedRun(
          902,
          'CI',
          branch: 'claude/ticket-3-reliable-feed',
          createdAt: '2026-11-13T08:53:16Z',
        ),
        failedRun(
          901,
          'CI',
          branch: 'claude/ticket-3-reliable-feed',
          createdAt: '2026-11-13T08:52:09Z',
        ),
        failedRun(
          900,
          'CI',
          branch: 'claude/ticket-32-ci-gate',
          createdAt: '2026-11-12T11:00:00Z',
        ),
      ]);
      github.issueEvents.addAll([
        labeled(
          'ready-for-agent',
          issue: 60,
          title: 'Nightly Android check failed',
          at: '2026-11-13T14:04:13Z',
        ),
        labeled(
          'ready-for-human',
          issue: 58,
          title: 'Impossible on purpose',
          at: '2026-11-13T14:04:02Z',
        ),
        labeled(
          'ready-for-human',
          issue: 57,
          title: 'Handed back, then closed',
          at: '2026-11-13T13:00:00Z',
          state: 'closed',
        ),
        labeled(
          'ready-for-human',
          issue: 55,
          title: 'Handed back, then made ready for an agent again',
          at: '2026-11-13T12:00:00Z',
          labelsNow: ['ready-for-agent'],
        ),
        labeled(
          'ready-for-human',
          issue: 12,
          title: 'Brand Ad video playback',
          at: '2026-11-12T20:00:00Z',
        ),
      ]);
      github.comments[58] = [
        comment(
          'Stafeed orchestrator gave up: the ticket cannot be done.',
          at: '2026-11-13T14:04:00Z',
        ),
      ];
    });

    test('lists the PRs merged since the last day, newest first', () async {
      final body = await postedSummary();

      expect(
        body,
        contains(
          '**Merged**\n'
          '- #61 Orchestrator is live (#41)\n'
          '- #56 Reliable feed (#3)\n'
          '\n',
        ),
      );
      expect(body, isNot(contains('#46')));
      expect(body, isNot(contains('#52')));
      expect(body, isNot(contains('No activity')));
    });

    test('lists failed runs, grouped by PR or by branch, with the latest '
        'run linked', () async {
      final body = await postedSummary();

      expect(
        body,
        contains(
          '**Failed**\n'
          '- Nightly Android check on `main`: 1 failed run '
          '([latest](https://github.com/danieljreije/stafeed/actions/runs/903))\n'
          '- CI on PR #56 Reliable feed (#3): 2 failed runs '
          '([latest](https://github.com/danieljreije/stafeed/actions/runs/902))\n'
          '\n',
        ),
      );
      expect(body, isNot(contains('runs/900')));
    });

    test('lists tickets newly handed back as ready-for-human that still '
        'wait for the owner, and says when the orchestrator gave up', () async {
      final body = await postedSummary();

      expect(
        body,
        contains(
          '**Handed to you (`ready-for-human`)**\n'
          '- #58 Impossible on purpose (the orchestrator gave up)\n'
          '\n',
        ),
      );
      expect(body, isNot(contains('#57')));
      expect(body, isNot(contains('#55')));
      expect(body, isNot(contains('#12')));
    });

    test('ends with the next ticket', () async {
      final body = await postedSummary();

      expect(body, endsWith('**Next**\n- #4 03: Feed Item kinds & labels'));
    });

    test('says "none" under a heading with nothing to list', () async {
      github.failedRuns.clear();
      github.issueEvents.clear();

      final body = await postedSummary();

      expect(body, contains('**Failed**\n- none\n'));
      expect(body, contains('**Handed to you (`ready-for-human`)**\n- none\n'));
    });
  });

  group('since the last summary', () {
    setUp(() {
      github.pulls.addAll([
        pull(
          61,
          'Merged two days ago, after the last summary (#41)',
          branch: 'claude/ticket-41-x',
          mergedAt: '2026-11-12T09:00:00Z',
        ),
        pull(
          56,
          'Merged before the last summary (#3)',
          branch: 'claude/ticket-3-x',
          mergedAt: '2026-11-12T05:00:00Z',
        ),
      ]);
      github.comments[1] = [
        comment('$summaryMarker\nNo activity.', at: '2026-11-11T06:00:00Z'),
        comment('$summaryMarker\nNo activity.', at: '2026-11-12T06:00:30Z'),
        comment('A note from the owner.', at: '2026-11-13T10:00:00Z'),
      ];
    });

    test('a missed day is caught up: the summary covers everything since '
        'the last summary comment', () async {
      final body = await postedSummary();

      expect(body, contains('Since 2026-11-12 06:00 UTC.'));
      expect(body, contains('- #61 Merged two days ago'));
      expect(body, isNot(contains('#56')));
    });
  });

  group('writes', () {
    setUp(() {
      github.pulls.addAll([
        for (var n = 300; n > 100; n--)
          pull(n, 'Old PR $n', branch: 'b$n', mergedAt: '2026-10-01T00:00:00Z'),
      ]);
      github.subIssues[1] = [ticket(4, 'Has a PR far down the list')];
      github.pulls.add(
        pull(
          100,
          'Oldest PR (#4)',
          branch: 'x',
          mergedAt: '2026-09-01T00:00:00Z',
        ),
      );
    });

    test(
      'the one comment is the only write, however many pages it reads',
      () async {
        final body = await postedSummary();

        expect(github.reads.length, greaterThan(3));
        expect(github.postedComments, hasLength(1));
        // The PR for #4 is on the third page of pull requests.
        expect(body, contains('Next: nothing.'));
      },
    );

    test('a trial run posts nothing and returns the text', () async {
      final body = await runDailySummary(github, now: now, post: false);

      expect(github.postedComments, isEmpty);
      expect(body, startsWith(summaryMarker));
    });
  });
}
