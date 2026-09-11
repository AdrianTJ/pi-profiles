# pi profile: sol-trial

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
- Trust model: installing a profile runs its declared packages, same as any
  npm install. Read settings.json before installing someone else's profile.

## SoL-Pi config

This profile ships `sol-pi.json` (conservative: Action Fusion +
ObservationPack on, reducer + context compact off). `pi-profile install`
does not copy it — place it in the profile dir after installing:

```sh
pi-profile install <this-repo> sol-trial
cp profiles/sol-trial/sol-pi.json ~/.pi/profiles/sol-trial/sol-pi.json
```
