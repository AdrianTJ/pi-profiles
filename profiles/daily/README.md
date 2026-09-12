# pi profile: daily

A shareable config profile for the [pi coding agent](https://github.com/earendil-works/pi), installed with
the pi-profile wrapper: https://github.com/AdrianTJ/pi-profiles

## Install

```sh
pi-profile install <owner>/<this-repo-name>
```

Packages declared in settings.json are re-fetched from npm/git on first launch —
nothing here is vendored.

## Notes

- Credentials (auth.json, models-store.json) are deliberately not included;
  they are symlinked from your global config at install time.
- Extension entries in settings.json pointing at absolute local paths won't
  resolve on other machines. Publish those extensions as npm/git packages.
- `pi-transcribe.json` carries the dictation shortcut and model choice. Its
  model path is machine-specific: on a new machine pi-transcribe reports the
  model missing and asks you to choose one again.
- Trust model: installing a profile runs its declared packages, same as any
  npm install. Read settings.json before installing someone else's profile.
