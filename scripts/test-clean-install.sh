#!/usr/bin/env bash
set -euo pipefail

source_url="https://github.com/tessariq/comment-hygiene"
installer_package="skills@1.7.0"
# Amp discovery can refresh shared installer state, so clean OpenCode before it.
agents=(claude-code codex opencode amp)
report_path="${1:-}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

report_rows=()
overall_failure=0
opencode_cell_ok=0

fail() {
  printf 'clean-install: %s\n' "$*" >&2
  exit 1
}

command -v npx >/dev/null 2>&1 || fail "npx is required"
command -v git >/dev/null 2>&1 || fail "git is required"
command -v jq >/dev/null 2>&1 || fail "jq is required"
npx_path="$(type -P npx 2>/dev/null || true)"
git_path="$(type -P git 2>/dev/null || true)"
jq_path="$(type -P jq 2>/dev/null || true)"
[[ -n "$npx_path" && -n "$git_path" && -n "$jq_path" ]] \
  || fail "npx, git, and jq must resolve to executable files"

sandbox="$workdir/sandbox"
home="$sandbox/home"
config="$sandbox/config"
cache="$sandbox/cache"
tmpdir="$sandbox/tmp"
npmrc="$sandbox/npmrc"
npm_globalrc="$sandbox/npm-globalrc"
gitconfig="$sandbox/home/gitconfig"
mkdir -p "$home" "$config" "$cache" "$tmpdir"
: >"$npmrc"
: >"$npm_globalrc"
: >"$gitconfig"

clean_env() {
  local -a environment=(
    "PATH=$PATH"
    "HOME=$home"
    "XDG_CONFIG_HOME=$config"
    "XDG_CACHE_HOME=$cache"
    "TMPDIR=$tmpdir"
    "npm_config_cache=$cache/npm"
    "npm_config_userconfig=$npmrc"
    "npm_config_globalconfig=$npm_globalrc"
    "npm_config_update_notifier=false"
    "npm_config_fund=false"
    "npm_config_audit=false"
    "npm_config_ignore_scripts=true"
    "GIT_CONFIG_GLOBAL=$gitconfig"
    "GIT_CONFIG_NOSYSTEM=1"
    "GIT_CONFIG_SYSTEM=/dev/null"
    "GIT_TERMINAL_PROMPT=0"
    "DISABLE_TELEMETRY=1"
    "DO_NOT_TRACK=1"
    "NO_COLOR=1"
    "CI=1"
  )

  if [[ "${ALLOW_AMP_ENV:-0}" == 1 ]]; then
    local name
    for name in AMP_URL AMP_API_KEY AMP_WORKLOAD_IDENTITY_REQUEST_TOKEN \
      AMP_WORKLOAD_IDENTITY_TOKEN AMP_PROJECT_ID AMP_WORKSPACE_ID AMP_ORB AMP_EXECUTOR; do
      if [[ -n "${!name:-}" ]]; then
        environment+=("$name=${!name}")
      fi
    done
  fi

  env -i \
    "${environment[@]}" \
    "$@"
}

agent_env() {
  local agent="$1"
  shift
  if [[ "$agent" == amp ]]; then
    ALLOW_AMP_ENV=1 clean_env "$@"
  else
    clean_env "$@"
  fi
}

installer_version="$(cd "$workdir" && clean_env "$npx_path" --yes "$installer_package" --version 2>/dev/null)" \
  || fail "could not run npx $installer_package --version"
[[ "$installer_version" == "1.7.0" ]] \
  || fail "expected skills CLI 1.7.0, got $installer_version"

source_revision="$(cd "$workdir" && clean_env "$git_path" ls-remote -- "$source_url" refs/heads/main | awk 'NR == 1 { print $1 }')" \
  || fail "could not resolve the public source revision"
[[ "$source_revision" =~ ^[0-9a-f]{40}$ ]] \
  || fail "public source did not return a commit revision"
source_ref_url="$source_url/tree/$source_revision"

uncomment_path="$(type -P uncomment 2>/dev/null || true)"
[[ -n "$uncomment_path" ]] || fail "uncomment 3.7.0 is required; run through the pinned Mise environment"
uncomment_version="$(clean_env "$uncomment_path" --version 2>/dev/null)" \
  || fail "could not run uncomment --version"
[[ "$uncomment_version" == "uncomment 3.7.0" ]] \
  || fail "expected uncomment 3.7.0, got $uncomment_version"

agent_command() {
  case "$1" in
    claude-code) printf '%s\n' claude ;;
    codex) printf '%s\n' codex ;;
    amp) printf '%s\n' amp ;;
    opencode) printf '%s\n' opencode ;;
    *) return 1 ;;
  esac
}

expected_skill_path() {
  case "$1" in
    claude-code) printf '%s\n' '.claude/skills/comment-hygiene/SKILL.md' ;;
    codex|amp|opencode) printf '%s\n' '.agents/skills/comment-hygiene/SKILL.md' ;;
    *) return 1 ;;
  esac
}

frontmatter_matches() {
  local path="$1"
  local frontmatter

  frontmatter="$(awk '
    NR == 1 && $0 != "---" { exit 1 }
    NR == 1 { next }
    $0 == "---" { found = 1; exit }
    { print }
    END { if (!found) exit 1 }
  ' "$path")" || return 1
  grep -Fxq -- 'name: comment-hygiene' <<<"$frontmatter" \
    && grep -Fxq -- 'description: Review and reduce low-value code comments with AST-safe candidate detection from uncomment.' <<<"$frontmatter"
}

sanitize_report_value() {
  printf '%s' "$1" | tr '\r\n|' '   ' | sed 's/`/\\`/g'
}

destination_type() {
  local path="$1"
  if [[ -L "$path" ]]; then
    printf '%s\n' symlink
  elif [[ -f "$path" ]]; then
    printf '%s\n' regular-file
  else
    printf '%s\n' missing
  fi
}

runtime_check() {
  local cell_dir="$1"
  local skill_path="$2"
  local prerequisite="$cell_dir/prerequisite.sh"
  local target="$cell_dir/runtime.py"
  local before_hash
  local ordinary_output
  local broad_output

  awk '
    /^## Installed-skill runtime$/ { in_section = 1; next }
    /^## Source-repository workflow$/ { exit }
    in_section && /^```sh$/ && !in_block { in_block = 1; next }
    in_block && /^```$/ { exit }
    in_block { print }
  ' "$skill_path" >"$prerequisite"
  [[ -s "$prerequisite" ]] || return 1

  cat >"$target" <<'EOF'
"""Documentation remains in ordinary mode."""

# Ordinary narration.
URL = "https://example.test/docs/#fragment"

# ruff: noqa: F401
# ~keep
# This protected comment remains.
protected = True

# TODO: Keep this follow-up in broad mode.
value = 1
EOF

  before_hash="$(sha256sum "$target")"
  ordinary_output="$(cd "$cell_dir" && clean_env /bin/sh -c '
    . "$1"
    NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff -- runtime.py
  ' sh "$prerequisite")" || return 1
  grep -Fq 'would remove 1' <<<"$ordinary_output" || return 1
  [[ "$before_hash" == "$(sha256sum "$target")" ]] || return 1

  broad_output="$(cd "$cell_dir" && clean_env /bin/sh -c '
    . "$1"
    NO_COLOR=1 "$uncomment_path" --dry-run --verbose --diff \
      --remove-doc --remove-todo --remove-fixme -- runtime.py
  ' sh "$prerequisite")" || return 1
  grep -Fq 'would remove 3' <<<"$broad_output" || return 1
  [[ "$before_hash" == "$(sha256sum "$target")" ]] || return 1
  grep -Fq 'https://example.test/docs/#fragment' "$target" || return 1
  grep -Fq '# ruff: noqa: F401' "$target" || return 1
  grep -Fq '# ~keep' "$target" || return 1
  grep -Fq '# This protected comment remains.' "$target" || return 1
}

for agent in "${agents[@]}"; do
  cell_dir="$workdir/$agent"
  mkdir -p "$cell_dir"
  (cd "$cell_dir" && clean_env "$git_path" init -q)

  install_command="npx --yes $installer_package add $source_ref_url --skill comment-hygiene --agent $agent --yes"
  install_log="$cell_dir/install.log"
  if (cd "$cell_dir" && clean_env "$npx_path" --yes "$installer_package" add "$source_ref_url" \
    --skill comment-hygiene --agent "$agent" --yes >"$install_log" 2>&1); then
    install_status=pass
  else
    install_status=fail
    overall_failure=1
  fi

  expected_path="$(expected_skill_path "$agent")"
  installed_path="$cell_dir/$expected_path"
  destination="$(destination_type "$installed_path")"
  installed_relative="$expected_path"
  canonical_count="$(find "$cell_dir" -name SKILL.md ! -path '*/.git/*' \( -type f -o -type l \) | wc -l)"
  frontmatter_status=fail
  if [[ "$install_status" == pass && "$canonical_count" -eq 1 && -f "$installed_path" ]] \
    && frontmatter_matches "$installed_path"; then
    frontmatter_status=pass
  else
    overall_failure=1
  fi

  runtime_status=not-run
  if [[ "$frontmatter_status" == pass ]]; then
    if runtime_check "$cell_dir" "$installed_path"; then
      runtime_status='pass (ordinary/broad dry-runs and fixture preservation)'
    else
      runtime_status=fail
      overall_failure=1
    fi
  fi

  command_name="$(agent_command "$agent")"
  agent_version=unavailable
  discovery='unverified: agent executable unavailable'
  discovery_ok=0
  agent_path="$(type -P "$command_name" 2>/dev/null || true)"
  if [[ -n "$agent_path" ]]; then
    version_output="$cell_dir/agent-version.txt"
    if agent_env "$agent" "$agent_path" --version >"$version_output" 2>&1; then
      agent_version="$(head -n 1 "$version_output" | tr -d '\r')"
      agent_version="${agent_version%% (*}"
    else
      agent_version='version command failed'
    fi
    if [[ "$agent" == amp && "$frontmatter_status" == pass ]]; then
      discovery_json="$cell_dir/discovery.json"
      if (cd "$cell_dir" && agent_env "$agent" "$agent_path" skills list --json >"$discovery_json" 2>/dev/null); then
        base_dir="$("$jq_path" -r '.skills[] | select(.name == "comment-hygiene" and .source == "workspace-agents") | .baseDir' "$discovery_json" | head -n 1)"
        expected_base="$cell_dir/.agents/skills/comment-hygiene"
        case "$base_dir" in
          file://*) base_path="${base_dir#file://}" ;;
          *) base_path="$base_dir" ;;
        esac
        base_dir_real="$(readlink -f -- "$base_path" 2>/dev/null || true)"
        expected_base_real="$(readlink -f -- "$expected_base" 2>/dev/null || true)"
        if [[ -n "$base_dir_real" && "$base_dir_real" == "$expected_base_real" ]] \
          && cmp -s "$installed_path" "$base_dir_real/SKILL.md"; then
          discovery='amp skills list --json: workspace-agents at .agents/skills/comment-hygiene'
          discovery_ok=1
        else
          discovery='unverified: amp skills list --json did not report the installed workspace skill'
        fi
      else
        discovery='unverified: amp skills list --json failed'
      fi
    elif [[ "$agent" != amp ]]; then
      discovery='unverified: no supported non-interactive discovery command configured'
    fi
  fi

  cleanup_command="npx --yes $installer_package remove comment-hygiene --agent $agent --yes"
  cleanup_log="$cell_dir/remove.log"
  if (cd "$cell_dir" && clean_env "$npx_path" --yes "$installer_package" remove comment-hygiene \
    --agent "$agent" --yes >"$cleanup_log" 2>&1) \
    && [[ ! -e "$installed_path" && ! -L "$installed_path" ]]; then
    if [[ -e "$cell_dir/skills-lock.json" ]]; then
      cleanup_status='pass (skill path removed; skills-lock.json retained)'
    else
      cleanup_status='pass (skill path and lock file removed)'
    fi
  else
    cleanup_status='fail (cleanup command or installed path check failed)'
    overall_failure=1
  fi

  if [[ "$agent" == opencode && "$install_status" == pass && "$cleanup_status" == pass* ]]; then
    opencode_cell_ok=1
  fi

  support_status=unverified
  if [[ "$agent" == amp ]]; then
    if [[ "$opencode_cell_ok" -ne 1 ]] || [[ "$command_name" != amp ]] || [[ "$discovery_ok" -ne 1 ]] \
      || [[ "$runtime_status" != pass* ]] || [[ "$cleanup_status" != pass* ]]; then
      support_status='unverified (Amp or OpenCode cell did not pass every check)'
      overall_failure=1
    else
      support_status=verified
    fi
  fi

  safe_agent_version="$(sanitize_report_value "$agent_version")"
  report_rows+=("$(printf '| `%s` | `%s` | `%s` | `%s` | %s | `%s` | `%s` | `%s` | `%s` | %s | %s | `%s` | %s | **%s** |' \
    "$agent" "$installer_version" "$safe_agent_version" "$source_revision" "$install_status" "$install_command" "$installed_relative" "$destination" "$frontmatter_status" "$discovery" "$runtime_status" "$cleanup_command" "$cleanup_status" "$support_status")")
done

report_tmp="$workdir/report.md"
{
  printf '# Clean agent-skill installation verification\n\n'
  printf -- '- Installer: `%s`\n' "$installer_package"
  printf -- '- Installer version: `%s`\n' "$installer_version"
  printf -- '- Public source: `%s`\n' "$source_url"
  printf -- '- Public source revision: `%s`\n' "$source_revision"
  printf -- '- Runtime prerequisite: `uncomment 3.7.0` (`%s`)\n' "$uncomment_version"
  printf -- '- Environment: isolated temporary `HOME`, XDG config/cache, Git/npm config, and allowlisted command environment per agent\n'
  printf -- '- Claimed support threshold: Amp requires its executable, discovery, runtime, and cleanup plus a passing OpenCode install/cleanup cell; other cells remain unverified without a supported non-interactive discovery result.\n\n'
  printf '| Agent | Installer version | Agent version | Source revision | Install | Exact install command | Installed path | Destination | Frontmatter | Discovery evidence | Runtime audit | Exact cleanup command | Cleanup | Support |\n'
  printf '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n'
  for report_row in "${report_rows[@]}"; do
    printf '%s\n' "$report_row"
  done
  printf '\nAll temporary targets and logs are removed on exit; the report contains no temporary paths or command output.\n'
} >"$report_tmp"

if [[ -n "$report_path" ]]; then
  cp -- "$report_tmp" "$report_path"
fi
cat "$report_tmp"

if [[ "$overall_failure" -ne 0 ]]; then
  printf 'clean-install: one or more required verification cells failed\n' >&2
  exit 1
fi
