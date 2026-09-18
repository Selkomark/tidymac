# tidymac

Daily macOS cleanup: stale `~/Library/Caches` and `~/Library/Logs` files (30+ days),
brew/pip/npm/uv caches, Docker build cache + unused images/containers, and
Time Machine local snapshots.

## Install

Without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/Selkomark/tidymac/main/remote-install.sh | bash
curl -fsSL https://raw.githubusercontent.com/Selkomark/tidymac/main/remote-install.sh | bash -s -- --hour 3 --minute 30
```

`remote-install.sh` just downloads `tidymac.sh`, `install.sh`, and the plist
template to a temp dir and runs `install.sh` — read it before piping it to
`bash` if you want to check what it does first.

From a clone:

```bash
chmod +x install.sh
./install.sh                    # daily at 10:00
./install.sh --hour 3 --minute 30
./install.sh --sudo             # also lets tmutil run unattended (adds a sudoers rule)
```

Re-running `install.sh` updates the script/schedule in place.

## Use

```bash
launchctl kickstart gui/$(id -u)/com.selkomark.tidymac   # run now
~/bin/tidymac.sh --volumes                                # manual run incl. Docker volume prune (irreversible)
tail -f ~/Library/Logs/tidymac/tidymac.log
```

The scheduled run never prunes Docker volumes. If the Mac is asleep at the
scheduled time, launchd runs the job at next wake.

## Uninstall

```bash
./uninstall.sh
```
