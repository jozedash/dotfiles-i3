# apt download failures

`apt-download.timer` runs `/usr/local/bin/apt-download` weekly. When it fails, the reason is in `/var/lib/apt-download/error` and the critical notification shows its last lines. Nothing is installed by the timer, so a failure never leaves the system half-upgraded; the next run (or a manual one) simply tries again.

To retry now and watch it:

```sh
sudo systemctl start apt-download.service
journalctl -u apt-download.service -n 50
cat /var/lib/apt-download/error
```

| Error contains | Cause | Fix |
|---|---|---|
| `Could not get lock` | Update Manager or another apt run held the lock for over 10 minutes | Wait for it to finish, then retry |
| `Temporary failure resolving`, `Failed to fetch` | Offline, VPN or proxy blocking a mirror | Retry once online; if one mirror keeps failing, pick another in Update Manager → Edit → Software Sources |
| `NO_PUBKEY`, `is not signed` | A third-party repository's signing key expired or changed | Get the new key from the vendor's install instructions, or disable that repository in Software Sources |
| `Release file ... is not valid yet` | Clock is wrong | `timedatectl` should show `System clock synchronized: yes` |
| `held broken packages`, `unmet dependencies` | A third-party package pins an old dependency | Run `sudo apt full-upgrade` to see which package; update or remove it |
| `No space left on device` | `/var/cache/apt/archives` filled the disk | `sudo apt-get clean`, then retry |
