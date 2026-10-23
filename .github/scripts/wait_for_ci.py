"""Wait until the CI of the tagged commit has passed.

A tag is pushed onto a commit that is already on main, so GitHub has a push
triggered CI run for that commit -- possibly still running. The release must not
publish before every workflow of that push has finished successfully. The only
run this script ignores is the release run that started on the tag push itself.

The required set is discovered from the commit's own push runs, so a generated
project (which no longer has the template workflow) is gated by its CI alone.
"""

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request

PASSING = {"success", "skipped"}
POLL_SECONDS = 20
TIMEOUT_SECONDS = 45 * 60


def fetch_runs(repo, sha, token):
    url = (
        f"https://api.github.com/repos/{repo}/actions/runs?head_sha={sha}&per_page=100"
    )
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)["workflow_runs"]


def selected_runs(runs, sha, own_run_id):
    """Return the latest attempt of every push-triggered workflow of the commit."""
    latest = {}
    for run in runs:
        if run["event"] != "push" or run["head_sha"] != sha or run["id"] == own_run_id:
            continue
        key = run["workflow_id"]
        current = latest.get(key)
        if current is None or (run["run_attempt"], run["id"]) > (
            current["run_attempt"],
            current["id"],
        ):
            latest[key] = run
    return latest


def summary(runs):
    """Classify the selected runs as (pending, failed). Both empty means passed."""
    pending = []
    failed = []
    for run in runs.values():
        name = run.get("name") or f"workflow {run['workflow_id']}"
        if run["status"] != "completed":
            pending.append(f"{name} ({run['status']})")
        elif run["conclusion"] not in PASSING:
            failed.append(f"{name} ({run['conclusion']})")
    return pending, failed


def self_test():
    base = {
        "event": "push",
        "head_sha": "abc",
        "run_attempt": 1,
        "status": "queued",
        "conclusion": None,
    }
    queued = {**base, "id": 1, "workflow_id": 10, "name": "CI"}
    other_ref = {
        **base,
        "id": 2,
        "workflow_id": 20,
        "name": "PR",
        "event": "pull_request",
    }
    own_run = {
        **base,
        "id": 3,
        "workflow_id": 30,
        "name": "Release",
        "status": "in_progress",
    }
    failed_attempt = {**queued, "id": 4, "status": "completed", "conclusion": "failure"}
    passing_attempt = {
        **queued,
        "id": 4,
        "run_attempt": 2,
        "status": "completed",
        "conclusion": "success",
    }

    runs = selected_runs([queued, other_ref, own_run], "abc", 3)
    assert list(runs) == [10], runs
    assert summary(runs) == (["CI (queued)"], []), summary(runs)

    assert summary(selected_runs([failed_attempt], "abc", 3)) == ([], ["CI (failure)"])
    # A rerun of a failed workflow supersedes the earlier attempt.
    assert summary(selected_runs([failed_attempt, passing_attempt], "abc", 3)) == (
        [],
        [],
    )
    assert selected_runs([{**queued, "head_sha": "def"}], "abc", 3) == {}
    print("wait_for_ci self-test passed")
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", default=os.environ.get("GITHUB_REPOSITORY"))
    parser.add_argument("--sha", default=os.environ.get("GITHUB_SHA"))
    parser.add_argument("--run-id", type=int, default=os.environ.get("GITHUB_RUN_ID"))
    parser.add_argument("--timeout", type=int, default=TIMEOUT_SECONDS)
    parser.add_argument("--poll", type=int, default=POLL_SECONDS)
    parser.add_argument(
        "--self-test", action="store_true", help="check the selection logic offline"
    )
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    if not args.repo or not args.sha or args.run_id is None:
        parser.error(
            "--repo, --sha and --run-id (or the GITHUB_* variables) are required"
        )
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        parser.error("GH_TOKEN or GITHUB_TOKEN must be set")

    deadline = time.monotonic() + args.timeout
    while True:
        try:
            runs = selected_runs(
                fetch_runs(args.repo, args.sha, token), args.sha, args.run_id
            )
        except (urllib.error.URLError, TimeoutError) as error:
            # A transient API failure must not turn into a published release.
            print(f"GitHub API request failed, retrying: {error}", flush=True)
        else:
            if not runs:
                print(
                    f"No push-triggered workflow for {args.sha} yet, waiting.",
                    flush=True,
                )
            else:
                pending, failed = summary(runs)
                if failed:
                    print(
                        f"CI for {args.sha} did not pass: {', '.join(failed)}",
                        file=sys.stderr,
                    )
                    return 1
                if not pending:
                    print(
                        f"CI for {args.sha} passed: {len(runs)} workflow(s).",
                        flush=True,
                    )
                    return 0
                print(f"Waiting for: {', '.join(pending)}", flush=True)

        if time.monotonic() >= deadline:
            print(
                f"CI for {args.sha} did not complete within {args.timeout}s",
                file=sys.stderr,
            )
            return 1
        time.sleep(args.poll)


if __name__ == "__main__":
    sys.exit(main())
