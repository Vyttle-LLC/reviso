# History bound

Binding on every lens that reads git history or prior review feedback —
the `history` and `prior-reviews` finders, and the same lenses applied
inline by the single-pass review.

**The change under review defines the world you can see.** Evidence
reachable only through commits that are not ancestors of the change's head
is inadmissible: sibling branches, later commits on the same branch, and
anything else `git log --all` reaches that the change itself cannot. Never
cite such a commit as evidence, and never return a candidate that rests
solely on one — having seen it, proceed as though it were absent.

Prefer history queries that cannot leave the change behind
(`git log <head>`, `git log <base>..<head>`, `git blame <head> -- <file>`).
When a commit's reachability is in doubt, check it:

```sh
git merge-base --is-ancestor <sha> <head>   # exit 0 = admissible
```

The rule covers `gh` the same way: a pull request merged after the change's
head is not prior feedback, it is the future.

On a user's real branch this excludes nothing — there is no future to
reach, so the lens behaves exactly as it always has. It is load-bearing in
evaluation: every corpus case drawn from this repository sits in an object
store that also holds the commits which later fixed the very issues under
review, and a lens reading those reports a recall it did not earn.
