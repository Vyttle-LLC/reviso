# Reviso deterministic detectors — parses a -U0 unified diff on stdin and
# emits one TSV line per finding: file <TAB> line <TAB> detector-id.
# Detectors here must be FP-free by construction (see DISCOVERY.md);
# anything requiring judgment belongs to the anti-slop finder instead.

# A "+++ " line is a file header only right after a "--- " line; otherwise
# it is an added line whose content starts with "++ " (e.g. C-family code).
{ after_minus = prev_minus; prev_minus = ($0 ~ /^--- /) }

after_minus && /^\+\+\+ / {
  file = substr($0, 5)
  sub(/^b\//, "", file)
  is_md   = (file ~ /\.(md|markdown|mdx)$/)
  is_test = (file ~ /(^|\/)(__tests__|tests?|spec)\// || file ~ /\.(test|spec)\.[A-Za-z]+$/)
  is_example = (file ~ /(^|\/)(examples?|demos?|samples?|fixtures?)(\/|$)/)
  cs = 0
  next
}

/^@@ / {
  # -U0 hunk header: new-file line counting starts at the "+c" value.
  match($0, /\+[0-9]+/)
  nl = substr($0, RSTART + 1, RLENGTH - 1) + 0
  next
}

/^\+/ {
  line = nl; nl++
  c = substr($0, 2)

  # conflict: all three markers, in order, with a ref label after the arrows.
  # Suppressed in markdown (docs teaching conflict resolution are not slop).
  if (!is_md) {
    if      (c ~ /^<<<<<<< /)            { cs = 1; csline = line }
    else if (cs == 1 && c ~ /^=======\r?$/) { cs = 2 }
    else if (cs == 2 && c ~ /^>>>>>>> /) { printf "%s\t%d\tconflict\n", file, csline; cs = 0 }
  }

  # placeholder: language presenting unimplemented code as implemented.
  # Suppressed in markdown and example/demo/sample/fixture paths, where
  # narrating a stand-in is legitimate.
  if (!is_md && !is_example) {
    lc = tolower(c)
    if (lc ~ /in a real (implementation|app|application|system|project)/ ||
        lc ~ /in production,? you would/ ||
        lc ~ /a real implementation would/) {
      printf "%s\t%d\tplaceholder\n", file, line
    }
  }

  # testfocus: focus modifiers in test files.
  if (is_test) {
    if (c ~ /(^|[^A-Za-z0-9_.])(it|test|describe|context)\.only[ \t]*\(/ ||
        c ~ /(^|[^A-Za-z0-9_.])(fit|fdescribe)[ \t]*\(/) {
      printf "%s\t%d\ttestfocus\n", file, line
    }
  }
  next
}
