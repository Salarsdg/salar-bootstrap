#!/usr/bin/env bash
# Public GitHub bootstrapper for privately hosted Salar install.sh.
# Only this file should be uploaded to a PUBLIC repository.
set -Eeuo pipefail
umask 077

die(){ printf '[ERROR] %s\n' "$*" >&2; exit 1; }
[[ "$(id -u)" == 0 ]] || die 'Run with sudo: sudo bash bootstrap.sh'
[[ -r /dev/tty ]] || die 'Interactive terminal required'
command -v curl >/dev/null || die 'curl is required to run this bootstrapper'
command -v python3 >/dev/null || {
  apt-get update -qq && apt-get install -y -qq python3 || die 'Could not install Python3'
}

printf '\nPrivate GitHub repository (format: OWNER/REPOSITORY): ' >/dev/tty
read -r github_repo </dev/tty
[[ "$github_repo" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || die 'Invalid repository name'
printf 'Git ref (branch, tag or commit; Enter for main): ' >/dev/tty
read -r github_ref </dev/tty
github_ref="${github_ref:-main}"
[[ "$github_ref" =~ ^[A-Za-z0-9_.-]+$ ]] || die 'Invalid ref; prefer a tag or commit'
printf 'Fine-grained GitHub token (Contents: Read only; hidden): ' >/dev/tty
read -rs gh_token </dev/tty
printf '\n' >/dev/tty
[[ -n "$gh_token" ]] || die 'Token required for private repository'

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
# Keep the token out of process arguments and shell history. Do not export it.
printf 'header = "Authorization: Bearer %s"\nheader = "Accept: application/vnd.github+json"\n' "$gh_token" > "$tmpdir/headers.curl"
unset gh_token
chmod 600 "$tmpdir/headers.curl"

printf '\nFetching private installer through GitHub API...\n'
curl --fail --silent --show-error --retry 2 --config "$tmpdir/headers.curl" \
  "https://api.github.com/repos/$github_repo/contents/install.sh?ref=$github_ref" \
  -o "$tmpdir/response.json" || die 'GitHub fetch failed. Check token, repository and ref.'
rm -f "$tmpdir/headers.curl"
python3 - "$tmpdir/response.json" "$tmpdir/install.sh" <<'PY'
import base64, json, pathlib, sys
payload=json.loads(pathlib.Path(sys.argv[1]).read_text())
if payload.get('type') != 'file' or payload.get('encoding') != 'base64':
    raise SystemExit('GitHub did not return a base64 file. Check the install.sh path.')
encoded=payload.get('content', '').replace('\n','')
data=base64.b64decode(encoded,validate=True)
if not data.startswith(b'#!/usr/bin/env bash') or len(data) > 2_000_000:
    raise SystemExit('Unexpected installer contents or size.')
pathlib.Path(sys.argv[2]).write_bytes(data)
PY
chmod 600 "$tmpdir/install.sh"
# Check embedded source archive before running anything as root.
bash "$tmpdir/install.sh" --verify
printf '\nInstaller source downloaded and bundle digest checked. Beginning setup...\n'
bash "$tmpdir/install.sh"
