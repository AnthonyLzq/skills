#!/usr/bin/env bash
# install.sh — install AnthonyLzq Skills into Claude Code, OpenCode, and Copilot.
# See --help and README.md.
set -euo pipefail

usage() {
  cat <<'USAGE'
install.sh — install AnthonyLzq Skills into agent skill directories.

Usage: ./install.sh [options]

Options:
  --agent <auto|opencode|claude|copilot>  Target agent. Default: auto — every
                                          agent whose target dir can be created.
  --global                                Install into the user-level skill dir.
  --project [DIR]                         Install into project-level skill dirs.
                                          Default DIR: current directory. This
                                          is also the default scope when neither
                                          --global nor --project is given.
  --skills all|<name[,name...]>           Skills to install. Default: all.
  --copy                                  Copy instead of symlinking.
  --unlink                                Remove previously installed symlinks
                                          for the selected agents and scope.
  --force                                 Replace an existing non-symlink target
                                          (refused without this flag).
  -h, --help                              Show this help and exit.

Scopes:
  agent      global scope                  project scope
  opencode   ~/.config/opencode/skills     <DIR>/.opencode/skills
  claude     ~/.claude/skills              <DIR>/.claude/skills
  copilot    none (project only)           <DIR>/.github/skills

Skills are symlinked (or copied with --copy) into the target dir, one entry per
skills/<name> folder. Re-runs are idempotent: nothing already identical is done.

Personalization: in the host repo, add .skills/<skill>.local.md to override
host-specific values. See README.md.
USAGE
}

die() { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
warn() { printf 'install.sh: %s\n' "$*" >&2; }
note() { printf 'install.sh: %s\n' "$*"; }

# Resolve the repo root even when invoked through a symlink.
script="${BASH_SOURCE[0]:-$0}"
while [ -L "$script" ]; do
  dir="$(cd "$(dirname "$script")" && pwd -P)"
  script="$(readlink "$script")"
  case "$script" in /*) ;; *) script="$dir/$script" ;; esac
done
repo_root="$(cd "$(dirname "$script")" && pwd -P)"

agent=auto
scope=
project_dir=
skills_spec=all
mode=link
unlink=0
force=0

while [ $# -gt 0 ]; do
  case "$1" in
    --agent)     [ "${2:-}" != "" ] || die "--agent requires a value"
                 agent="$2"; shift 2 ;;
    --agent=*)   agent="${1#*=}"; shift ;;
    --global)    scope=global; shift ;;
    --project)   if [ "${2:-}" = "" ] || [ "${2:0:1}" = "-" ]; then
                   scope=project; shift
                 else
                   scope=project; project_dir="$2"; shift 2
                 fi ;;
    --project=*) scope=project; project_dir="${1#*=}"; shift ;;
    --skills)    [ "${2:-}" != "" ] || die "--skills requires a value"
                 skills_spec="$2"; shift 2 ;;
    --skills=*)  skills_spec="${1#*=}"; shift ;;
    --copy)      mode=copy; shift ;;
    --unlink)    unlink=1; shift ;;
    --force)     force=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    --)          shift; break ;;
    -*)          die "unknown option: '$1' (see --help)" ;;
    *)           die "unexpected argument: '$1' (see --help)" ;;
  esac
done
[ "$#" -eq 0 ] || die "unexpected arguments: $*"

case "$agent" in auto|opencode|claude|copilot) ;; *)
  die "invalid --agent '$agent' (auto|opencode|claude|copilot)"
esac
[ -n "$scope" ] || scope=project
if [ "$agent" = "copilot" ] && [ "$scope" = "global" ]; then
  die "copilot has no global scope; use --project"
fi
if [ -n "$project_dir" ]; then
  [ -d "$project_dir" ] || die "project dir does not exist: $project_dir"
  project_dir="$(cd "$project_dir" && pwd -P)"
fi
[ "$scope" = project ] && [ -z "$project_dir" ] && project_dir="$PWD"
if [ "$unlink" -eq 1 ] && [ "$mode" = copy ]; then
  die "--unlink removes symlinks only; drop --copy"
fi

skills_root="$repo_root/skills"
valid_name() { case "$1" in "-"*|*[!a-z0-9_-]*|"") return 1 ;; esac }
skill_dir_ok() { [ -d "$1" ] && [ -f "$1/SKILL.md" ]; }
available_names() {
  [ -d "$skills_root" ] || { printf 'none yet'; return; }
  out=
  for s in "$skills_root"/*; do
    skill_dir_ok "$s" && out="${out:+$out, }${s##*/}"
  done
  printf '%s' "${out:-none yet}"
}

declare -a agents=()
if [ "$agent" = auto ]; then
  if [ "$scope" = global ]; then
    agents=(opencode claude)
    note "auto: copilot has no global scope; skipped"
  else
    agents=(opencode claude copilot)
  fi
else
  agents=("$agent")
fi

declare -a skills=()
if [ "$skills_spec" = all ]; then
  for s in "$skills_root"/*; do
    if skill_dir_ok "$s"; then
      name="${s##*/}"
      valid_name "$name" || die "invalid skill folder name: $name"
      skills+=("$name")
    fi
  done
  if [ "${#skills[@]}" -eq 0 ]; then
    printf 'Nothing to do: no skills found in %s — add skills/<name>/SKILL.md first.\n' "$skills_root"
    exit 0
  fi
else
  IFS=',' read -r -a wanted <<< "$skills_spec"
  for name in "${wanted[@]}"; do
    name="${name// /}"
    [ -n "$name" ] || continue
    valid_name "$name" || die "invalid skill name '$name'"
    skill_dir_ok "$skills_root/$name" || die "unknown skill '$name' (available: $(available_names))"
    skills+=("$name")
  done
  [ "${#skills[@]}" -gt 0 ] || die "no usable skills in --skills '$skills_spec'"
fi

dest_for() {
  local a="$1"
  if [ "$scope" = global ]; then
    case "$a" in
      opencode) printf '%s' "$HOME/.config/opencode/skills" ;;
      claude)   printf '%s' "$HOME/.claude/skills" ;;
      *)        die "agent '$a' has no global scope" ;;
    esac
  else
    case "$a" in
      opencode) printf '%s' "$project_dir/.opencode/skills" ;;
      claude)   printf '%s' "$project_dir/.claude/skills" ;;
      copilot)  printf '%s' "$project_dir/.github/skills" ;;
      *)        die "invalid agent '$a'" ;;
    esac
  fi
}

declare -a rows=()

if [ "$unlink" -eq 1 ]; then
  for a in "${agents[@]}"; do
    dir=$(dest_for "$a")
    removed="" skipped=""
    for s in "${skills[@]}"; do
      link="$dir/$s"
      if [ -L "$link" ]; then
        if [ "$(readlink -f "$link")" = "$(readlink -f "$skills_root/$s")" ]; then
          rm "$link"
          removed="${removed:+$removed, }$s"
        else
          warn "symlink from another source, leaving untouched: $link"
          skipped="${skipped:+$skipped, }$s"
        fi
      elif [ -e "$link" ]; then
        warn "not a symlink from this repo, leaving as-is: $link"
        skipped="${skipped:+$skipped, }$s"
      fi
    done
    rows+=("$a|$scope|$dir|${removed:-none}|${skipped:-none}")
  done
  printf 'Unlinked:\n'
  for row in "${rows[@]}"; do
    IFS='|' read -r a sc d rm_l sk_l <<< "$row"
    printf '  %-10s %-9s %s\n' "$a" "$sc" "$d"
    printf '  %-21s removed: %s\n' "" "$rm_l"
    printf '  %-21s untouched: %s\n' "" "$sk_l"
  done
  exit 0
fi

total_installed=0
refused_total=0
for a in "${agents[@]}"; do
  dir=$(dest_for "$a")
  mkdir -p "$dir" 2>/dev/null || die "cannot create target dir: $dir"
  installed="" already="" refused=""
  for s in "${skills[@]}"; do
    src="$skills_root/$s"
    dst="$dir/$s"
    if [ -L "$dst" ]; then
      if [ "$(readlink -f "$dst")" = "$(readlink -f "$src")" ]; then
        already="${already:+$already, }$s"
        continue
      fi
      if [ "$force" -eq 1 ]; then
        warn "WARNING: --force is replacing the existing symlink at $dst (points to $(readlink "$dst"))"
        rm "$dst"
      else
        warn "refusing to touch foreign symlink $dst (use --force to replace it)"
        refused="${refused:+$refused, }$s"
        refused_total=$((refused_total + 1))
        continue
      fi
    elif [ -e "$dst" ]; then
      if [ "$mode" = copy ] && [ -d "$dst" ] && diff -r -q "$src" "$dst" >/dev/null 2>&1; then
        already="${already:+$already, }$s"
        continue
      fi
      if [ "$force" -eq 1 ]; then
        if [ -d "$dst" ]; then kind=dir; else kind=file; fi
        warn "WARNING: --force is replacing the existing $kind at $dst"
        rm -rf "$dst"
      else
        warn "refusing to overwrite existing target: $dst (re-run with --force)"
        refused="${refused:+$refused, }$s"
        refused_total=$((refused_total + 1))
        continue
      fi
    fi
    if [ "$mode" = link ]; then
      if rel="$(realpath -m --relative-to="$dir" "$src" 2>/dev/null)" && [ -n "$rel" ]; then
        ln -s "$rel" "$dst"
      else
        ln -s "$src" "$dst"
      fi
    else
      cp -R "$src" "$dst"
    fi
    installed="${installed:+$installed, }$s"
    total_installed=$((total_installed + 1))
  done
  rows+=("$a|$scope|$dir|${installed:-none}|${already:-none}|${refused:-none}")
done

printf 'Installed:\n'
for row in "${rows[@]}"; do
  IFS='|' read -r a sc d ins al rf <<< "$row"
  printf '  %-10s %-9s %s\n' "$a" "$sc" "$d"
  printf '  %-21s installed: %s\n' "" "$ins"
  printf '  %-21s already present: %s\n' "" "$al"
  printf '  %-21s refused: %s\n' "" "$rf"
done

if [ "$scope" = project ] && [ "$total_installed" -gt 0 ]; then
  printf "\nTip: add .skills/<skill>.local.md to personalize this repo's skills.\n"
fi

[ "$refused_total" -eq 0 ] || die "$refused_total target(s) refused; re-run with --force to replace them"
exit 0
