sloppy sandbox for sloppy tools

for example, to run a sandbox in the `~/foo` directory, while having the `uv`, `git` and `python3` packages available:

```
$ nix run '.#shell' -- ~/foo 'nixpkgs#uv' 'nixpkgs#git' 'nixpkgs#python3'
```

Then, in the sandbox, run `jarvis`
