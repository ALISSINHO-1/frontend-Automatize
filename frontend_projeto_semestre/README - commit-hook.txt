README - COMMIT-HOOK
================================================================================

1. The hook is already included in this repository.

2. Install it once after cloning/extracting the repository:

   Windows:
   - Double-click setup_hook.bat

   Git Bash / Linux:
   - ./setup_hooks.sh

3. Use commits with one of these formats:

   FEAT: description of a new feature
   FIX: description of a bug fix
   CHORE: description of maintenance or adjustment

4. Automatic version rules:

   FEAT  -> increments MINOR and resets PATCH to zero.
   FIX   -> increments PATCH.
   CHORE -> increments PATCH.

5. On each accepted commit, the hook automatically:

   - updates version in the Flutter pubspec.yaml;
   - increments the Flutter build number after the + sign;
   - prefixes the commit message with vMAJOR.MINOR.PATCH;
   - prepends an entry to CHANGELOG.md;
   - creates or updates the local Git tag for the new version.

6. Example starting from version 1.0.0+1:

   git commit -m "FEAT: add login page"
   -> pubspec.yaml: 1.1.0+2
   -> commit: v1.1.0 - FEAT: add login page
   -> tag: v1.1.0

   git commit -m "FIX: correct login validation"
   -> pubspec.yaml: 1.1.1+3
   -> commit: v1.1.1 - FIX: correct login validation
   -> tag: v1.1.1

7. The hook creates tags locally. Push tags when desired with:

   git push origin --tags

8. To confirm the hook path:

   git config core.hooksPath

   Expected value:
   scripts/hooks

================================================================================
