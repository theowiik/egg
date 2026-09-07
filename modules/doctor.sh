failures=0
ok() { printf '  ok    %s\n' "$*"; }
fail() { printf '  FAIL  %s\n' "$*"; failures=$((failures + 1)); }

printf 'egg doctor\n\n'
if [ -f "$dir/flake.nix" ]; then
  ok "repository: $dir"
else
  fail "repository missing: $dir (set EGG_DIR)"
fi

for tool in zsh starship fastfetch fzf fd bat zoxide hx git home-manager; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool"
  else
    fail "$tool is missing from PATH; rebuild and open a new login shell"
  fi
done

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
for file in zsh/.zshrc starship.toml fastfetch/config.jsonc; do
  if [ -r "$config_home/$file" ]; then
    ok "$file"
  else
    fail "$config_home/$file missing; run hms"
  fi
done

if [ "${EGG_PREVIEW:-}" = 1 ]; then
  ok "temporary preview (not activated)"
elif [ -e "${XDG_STATE_HOME:-$HOME/.local/state}/nix/profiles/home-manager" ] ||
     [ -e "/nix/var/nix/profiles/per-user/$(id -un)/home-manager" ]; then
  ok "Home Manager generation exists"
else
  fail "no Home Manager generation; run nix run .#install from the repository"
fi

if command -v git >/dev/null 2>&1; then
  git_name=$(git config --global --get user.name || true)
  git_email=$(git config --global --get user.email || true)
  if [ -z "$git_name" ]; then
    fail "Git user.name is unset; set egg.git.userName in your host config"
  else
    ok "Git user.name: $git_name"
  fi
  case "$git_email" in
    ''|*@example.com|*@example-corp.com)
      fail "Git email is unset or a placeholder; set egg.git.userEmail in your host config"
      ;;
    *@*) ok "Git user.email: $git_email" ;;
    *) fail "Git user.email needs an email address" ;;
  esac
fi

printf '\n%s issue(s) found.\n' "$failures"
[ "$failures" -eq 0 ]
