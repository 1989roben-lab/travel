#!/bin/bash
set -euo pipefail

fail() {
  printf '安装未完成：%s\n' "$*" >&2
  exit 1
}

[[ $# -eq 0 ]] || fail '用法：bash install-macos.sh'
[[ "$(uname -s)" == Darwin ]] || fail '请在 macOS 上运行此脚本。'
for program in git node npm; do
  command -v "$program" >/dev/null || fail "请先安装 ${program}。Node.js 要求 22.9 或更新版本。"
done
node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || major === 22 && minor >= 9 ? 0 : 1)' ||
  fail '请先安装 Node.js 22.9 或更新版本。'
node_bin=$(command -v node)
codex_bin=$(command -v codex || true)
if [[ -z "$codex_bin" ]]; then
  for app in '/Applications/ChatGPT.app' '/Applications/Codex.app'; do
    candidate="$app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS/codex"
    if [[ -x "$candidate" ]]; then
      codex_bin="$candidate"
      break
    fi
  done
fi
[[ -n "$codex_bin" ]] || fail '找不到 Codex CLI。请安装 Codex 或把 codex 加入 PATH。'

package_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
amap_patch="$package_dir/patches/foodnearby.patch"
dp_login_patch="$package_dir/patches/dianping-login.patch"
dp_rating_patch="$package_dir/patches/dianping-rating.patch"
skill_file="$package_dir/SKILL.md"
[[ -f "$amap_patch" && -f "$dp_login_patch" && -f "$dp_rating_patch" && -f "$skill_file" ]] ||
  fail '请完整解压 ZIP 后再运行。'

mkdir -p "${CODEX_HOME:-$HOME/.codex}"
CODEX_HOME=$(cd "${CODEX_HOME:-$HOME/.codex}" && pwd -P)
export CODEX_HOME
managed="$CODEX_HOME/mcp-servers/nearby-travel"
amap="$managed/foodnearby"
dp="$managed/dianping"
key_file="$amap/.env"
skill_dir="$CODEX_HOME/skills/nearby-travel"
lock="$CODEX_HOME/.nearby-travel-install-lock"
mkdir "$lock" 2>/dev/null || fail "另一次安装正在运行，或上次中断留下了锁目录 ${lock}。"
staging=
cleanup() {
  if [[ -n "$staging" ]]; then rm -rf -- "$staging"; fi
  rmdir -- "$lock"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

amap_revision=2f4de0c02352d362343d45c88a27b2f3b2601544
dp_revision=7886cc2996ad207e69b5277d83b6d28a422140e7
amap_receipt="$amap_revision $(git hash-object "$amap_patch")"
previous_dp_receipt="$dp_revision $(git hash-object "$dp_login_patch")"
dp_receipt="$previous_dp_receipt $(git hash-object "$dp_rating_patch")"

check_mcp() {
  local name=$1 entry=$2 output args_value
  if output=$("$codex_bin" mcp get "$name" --json 2>&1); then
    args_value=
    if [[ "$name" == nearby-amap ]]; then args_value="$key_file"; fi
    printf '%s' "$output" | "$node_bin" -e '
      const fs = require("node:fs");
      const [command, entry, keyFile] = process.argv.slice(1);
      const config = JSON.parse(fs.readFileSync(0, "utf8"));
      const transport = config.transport;
      const args = keyFile ? ["--env-file-if-exists=" + keyFile, entry] : [entry];
      if (!(config.enabled && transport?.type === "stdio" && transport.command === command
            && JSON.stringify(transport.args) === JSON.stringify(args)
            && (!keyFile || transport.env?.DOTENV_CONFIG_PATH === keyFile
                        && transport.env?.DOTENV_CONFIG_QUIET === "true"))) process.exit(1);
    ' "$node_bin" "$entry" "$args_value" ||
      fail "已有自定义 MCP 配置 ${name}，请检查其路径和启用状态。"
    printf 'present'
  else
    case "$output" in
      *"No MCP server named '$name' found."*) printf 'missing' ;;
      *) fail "无法读取 Codex 的 $name 配置。请检查 Codex CLI 和配置文件。";;
    esac
  fi
}

check_install() {
  local dir=$1 expected=$2 previous=${3:-$2} receipt
  if [[ -e "$dir" || -L "$dir" ]]; then
    [[ ! -L "$dir" && -f "$dir/.nearby-travel-release" && -f "$dir/dist/index.js" ]] ||
      fail "发现已有目录 ${dir}，版本或构建与此安装包不匹配。"
    receipt=$(cat "$dir/.nearby-travel-release")
    [[ "$receipt" == "$expected" || "$receipt" == "$previous" ]] ||
      fail "发现已有目录 ${dir}，版本或构建与此安装包不匹配。"
    printf '%s' "$receipt"
  fi
}

amap_config=$(check_mcp nearby-amap "$amap/dist/index.js")
dp_config=$(check_mcp nearby-dianping "$dp/dist/index.js")
check_install "$amap" "$amap_receipt" >/dev/null
installed_dp=$(check_install "$dp" "$dp_receipt" "$previous_dp_receipt")
upgrade_skill=false
if [[ -e "$skill_dir" || -L "$skill_dir" ]]; then
  [[ ! -L "$skill_dir" && ! -L "$skill_dir/SKILL.md" && -f "$skill_dir/SKILL.md" ]] ||
    fail "已有不同的 Skill 位于 ${skill_dir}。"
  if ! cmp -s "$skill_file" "$skill_dir/SKILL.md"; then
    installed_skill_hash=$(shasum -a 256 < "$skill_dir/SKILL.md")
    case "${installed_skill_hash%% *}" in
      72ef028df668215eaf47acfa60823ef017c9a1fba240c157f02aa7f14db4265f|bb31c37ac0e8e4c28ced4286f32698626fb00d2d2db1543bf9c75cd19bc7fc04|a0109ebf1684244f136a5565ab1679b9444574efc6d3552f49246556c1225893)
        upgrade_skill=true ;;
      *) fail "已有不同的 Skill 位于 ${skill_dir}。";;
    esac
  fi
fi

mkdir -p "$managed" "$CODEX_HOME/skills"
staging=$(mktemp -d "$managed/.install.XXXXXX")
build_server() {
  local target=$1 repo=$2 revision=$3 receipt=$4 patch_file
  shift 4
  git init -q "$target"
  git -C "$target" remote add origin "$repo"
  git -C "$target" fetch --quiet --depth 1 origin "$revision"
  git -C "$target" checkout --quiet --detach FETCH_HEAD
  [[ "$(git -C "$target" rev-parse HEAD)" == "$revision" ]] || fail '下载的 Git 提交与指定版本不符。'
  for patch_file in "$@"; do git -C "$target" apply "$patch_file"; done
  (cd "$target" && npm ci --ignore-scripts --no-audit --no-fund && npm run build)
  printf '%s\n' "$receipt" > "$target/.nearby-travel-release"
}

if [[ ! -d "$amap" ]]; then
  build_server "$staging/foodnearby" https://github.com/FunEnn/FoodNearBy-MCP.git "$amap_revision" "$amap_receipt" "$amap_patch"
fi
if [[ ! -d "$dp" ]]; then
  build_server "$staging/dianping" https://github.com/qianwj/dp-mcp.git "$dp_revision" "$dp_receipt" "$dp_login_patch" "$dp_rating_patch"
elif [[ "$installed_dp" == "$previous_dp_receipt" ]]; then
  [[ "$(git -C "$dp" rev-parse HEAD)" == "$dp_revision" ]] || fail '大众点评的本机源码版本已更改。'
  if ! git -C "$dp" apply --reverse --check "$dp_rating_patch" 2>/dev/null; then
    git -C "$dp" apply "$dp_rating_patch" || fail '大众点评的本机代码与评分补丁冲突。'
  fi
  (cd "$dp" && npm run build)
  printf '%s\n' "$dp_receipt" > "$staging/dp-receipt"
  mv "$staging/dp-receipt" "$dp/.nearby-travel-release"
fi
if [[ -d "$staging/foodnearby" ]]; then mv "$staging/foodnearby" "$amap"; fi
if [[ -d "$staging/dianping" ]]; then mv "$staging/dianping" "$dp"; fi
if [[ ! -e "$key_file" && ! -L "$key_file" ]]; then
  (umask 077; set -o noclobber; printf 'AMAP_API_KEY=\n' > "$key_file")
fi

if [[ "$amap_config" == missing ]]; then
  "$codex_bin" mcp add nearby-amap --env "DOTENV_CONFIG_PATH=$key_file" --env DOTENV_CONFIG_QUIET=true -- \
    "$node_bin" "--env-file-if-exists=$key_file" "$amap/dist/index.js"
fi
if [[ "$dp_config" == missing ]]; then
  "$codex_bin" mcp add nearby-dianping -- "$node_bin" "$dp/dist/index.js"
fi
if [[ ! -d "$skill_dir" ]]; then
  mkdir "$staging/skill"
  cp "$skill_file" "$staging/skill/SKILL.md"
  mv "$staging/skill" "$skill_dir"
elif [[ "$upgrade_skill" == true ]]; then
  cp "$skill_file" "$staging/SKILL.md"
  mv "$staging/SKILL.md" "$skill_dir/SKILL.md"
fi

printf '\n已安装 nearby-travel。首次使用请完成这两步，然后重开 Codex。\n'
printf '1. 在终端运行下列命令，在本机文件中填写自己的高德 Web 服务 Key。\n'
printf '   open -e %q\n' "$key_file"
printf '2. 退出正在使用大众点评的 Codex 会话，再运行下列命令。在打开的浏览器中登录，完成网站要求的验证，回终端按 Ctrl+C。\n'
printf '   %q %q\n' "$node_bin" "$dp/dist/login.js"
