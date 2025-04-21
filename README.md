# gitterbugs
A fast tree builder for any public GitHub repo via the linux shell

> `gitterbugs` (gbgs) clones, analyzes and renders a beautiful, readable and size-annotated tree of any GitHub repository in seconds.

---

## What It Does

`gitterbugs` turns this:

```
git clone https://github.com/torvalds/linux.git
cd linux
tree
```

...into a single elegant command:

```
gbgs https://github.com/torvalds/linux
```

And produces:

```
linux/
├── README (4.3K)
├── Makefile (7.1K)
├── arch/
│   └── x86/
│       └── entry.S (1.5K)
└── init/
    └── main.c (5.9K)
```

With human-readable file sizes, no junk and clean Unicode pipes for maximum legibility.

---

## Why It's Better

| Feature                     | `tree`          | `ls -R`        | `gitterbugs` |
|----------------------------|------------------|----------------|--------------|
| Recursive                  | yes              | yes            | yes          |
| Skips `.git`/dotfiles      | no               | no             | yes          |
| Pretty pipe tree layout    | yes              | no             | yes          |
| File sizes (human-readable)| no               | no             | yes          |
| GitHub repo support        | no               | no             | yes          |
| Single-command usage       | no               | no             | yes          |

---

## Quick Install

```
curl -fsSL  https://raw.githubusercontent.com/amosWeiskopf/gitterbugs/refs/heads/main/gitterbugs.sh | sh
```

Then just run:

```
gbgs https://github.com/YourOrg/YourRepo
e.g. gbgs https://github.com/public-apis/public-apis
```

---

## How It Works

1. Clones the GitHub repo (only once).
2. Recursively maps all files and directories (excluding hidden files).
3. Renders pipeview with:
   - Unicode branch characters (`├──`, `└──`)
   - File sizes: in B, K, or M
4. Saves tree to `reponame_tree.txt`

No internet access is required after the clone.  
No dependencies beyond standard Unix tools.

---

## Sample Output

```
YourRepo/
├── main.go (2.1K)
├── go.mod (122B)
├── internal/
│   ├── engine/
│   │   └── planner.go (4.2K)
│   └── api/
│       └── handler.go (3.3K)
└── README.md (1.5K)
```

---

## Tech Stack

- Written in pure Bash + AWK
- ~100ms runtime on typical repos
- Zero dependencies beyond `git`, `awk`, `find` and `parallel`

---

## License

MIT. Use it, remix it, monetize it, tattoo it on your face for all I care; enjoy. 

---

## Author

Crafted with obsession by [@AmosWeiskopf](https://github.com/amosWeiskopf)

---

## Future Enhancements

- `--json` or `--markdown` output
- Filetype filters (`--only .py`)
- GitHub Gist support

# Why I made this
I built this to procrastinate instead of actually getting some work done. I hope you too find gitterbugs helpful. If you do, please star me on github and buy me a mercedes. Thanks.
