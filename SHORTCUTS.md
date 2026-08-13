# Shortcuts

Shortcuts.app doesn't sync to machines on a different Apple account, and its files can't be installed from the command line. These iCloud links cover the gap: open one on the target machine, review the actions, click Add.

Links are snapshots. Editing a shortcut doesn't update an already-shared link — re-share and replace the URL here.

| Shortcut | Link |
|---|---|
| AirPods Max | https://www.icloud.com/shortcuts/77f30ddfb4a24e92b1b8caeef6ab171e |
| Quit All Apps | https://www.icloud.com/shortcuts/07456cc311aa4bfd894ab184fca95875 |
| Empty Trash | https://www.icloud.com/shortcuts/c7e7e7d7c7f04aa7b7f6af000b65d8da |
| Restart | https://www.icloud.com/shortcuts/a83f106e401c493e894d74d664134126 |
| Shut Down | https://www.icloud.com/shortcuts/109035b9cbdd45d8bd48014cf1dfe743 |

**AirPods Max** runs `zsh -ic 'airpods-max'`, so the target machine needs the `blueutil` package and the `airpods-max` function from `home/zshrc`. Both come with a rebuild. The addresses in that function are this account's headphones and won't transfer.

The links are public to anyone holding them. Keep work paths, hostnames, and internal tooling out of any shortcut shared this way.
