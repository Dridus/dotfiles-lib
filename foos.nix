# Files Out Of Store. Functionality to link to files directly in the source instead of in the
# nix store, intentionally breaking purity so that home-manager switch isn't required for all
# changes.
#
# Derived from https://github.com/outfoxxed/impurity.nix, but this version is simplified so it
# can be easily used as an partially applied module argument rather than globally in
# _module.args
{ lib }:
{ storeRoot, sourceRootSubdir }:
let
  inherit (builtins) getEnv;
  inherit (lib) types;
  inherit (lib.strings) removePrefix;

  foosSourceRoot = getEnv "FOOS_SOURCE_ROOT";

  resolveParents =
    let
      inherit (builtins)
        head
        length
        null
        split
        tail
        ;
      # my kingdom for pattern matching
      reassemble =
        ss:
        if ss == [ ] then
          ""
        else
          let
            prefix = head ss;
            tl = tail ss;
            groups = head tl;
            rest = tail tl;
          in
          prefix + (if tl == [ ] then "" else head groups + reassemble rest);
      maybeReassembleAndRecurse =
        ss:
        if ss == [ ] then
          ""
        else if length ss == 1 then
          head ss
        else
          resolveParents (reassemble ss);
    in
    str: maybeReassembleAndRecurse (split "/[^/]+/\\.\\.(/|$)" str);

  storeRootPrefix = resolveParents (toString storeRoot);
  relativePath =
    path:
    assert types.path.check path;
    removePrefix storeRootPrefix (toString path);

  mkOOSLink =
    pkgs: path:
    let
      relative = relativePath path;
      full = "${foosSourceRoot}/${sourceRootSubdir}/${relative}";
    in
    pkgs.runCommand "foos-${relative}" { } "ln -s ${full} $out";
in
pkgs: path:
assert types.path.check path;
if foosSourceRoot == "" then path else mkOOSLink pkgs path
