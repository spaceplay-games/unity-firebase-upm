# Unity Firebase UPM

Firebase Unity SDK packages for Unity Package Manager (UPM).

This repository automatically tracks the latest [Firebase Unity SDK](https://github.com/firebase/firebase-unity-sdk) releases and provides them in a UPM-compatible format by downloading directly from [Google's Unity Archive](https://developers.google.com/unity/archive#firebase).

## Available Packages

| Package | Description |
|---------|-------------|
| `com.google.firebase.app` | Firebase Core (required by all Firebase packages) |
| `com.google.firebase.analytics` | Google Analytics for Firebase |
| `com.google.firebase.crashlytics` | Firebase Crashlytics |
| `com.google.firebase.app-check` | Firebase App Check |
| `com.google.firebase.auth` | Firebase Authentication |
| `com.google.firebase.firestore` | Cloud Firestore |
| `com.google.firebase.functions` | Cloud Functions for Firebase |
| `com.google.firebase.storage` | Cloud Storage for Firebase |
| `com.google.firebase.database` | Firebase Realtime Database |
| `com.google.firebase.remote-config` | Firebase Remote Config |
| `com.google.firebase.messaging` | Firebase Cloud Messaging |
| `com.google.firebase.installations` | Firebase Installations |
| `com.google.external-dependency-manager` | External Dependency Manager (EDM4U) |

## Installation

### Option 1: Git URL (Recommended)

Add the packages to your Unity project's `Packages/manifest.json`:

```json
{
  "dependencies": {
    "com.google.external-dependency-manager": "https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.external-dependency-manager",
    "com.google.firebase.app": "https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.firebase.app",
    "com.google.firebase.analytics": "https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.firebase.analytics",
    "com.google.firebase.crashlytics": "https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.firebase.crashlytics",
    "com.google.firebase.app-check": "https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.firebase.app-check"
  }
}
```

### Option 2: Specific Version

Pin to a specific Firebase version using git tags:

```json
{
  "dependencies": {
    "com.google.firebase.app": "https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.firebase.app#v13.6.0"
  }
}
```

### Option 3: Unity Package Manager UI

1. Open Unity
2. Go to **Window > Package Manager**
3. Click the **+** button and select **Add package from git URL...**
4. Enter: `https://github.com/spaceplay-games/unity-firebase-upm.git?path=packages/com.google.firebase.app`
5. Repeat for each package you need

## Package Dependencies

Make sure to install packages in the correct order:

1. `com.google.external-dependency-manager` (required for resolving native dependencies)
2. `com.google.firebase.app` (required by all Firebase packages)
3. Other Firebase packages as needed

## Automatic Updates

This repository uses GitHub Actions to automatically check for new Firebase SDK releases daily. When a new version is detected:

1. Downloads individual packages from Google's Unity Archive
2. Extracts the UPM packages
3. Commits and pushes the changes
4. Creates a new GitHub release with the version tag

### Manual Trigger

You can trigger an update manually:

1. Go to the **Actions** tab in this repository
2. Select **Update Firebase Packages**
3. Click **Run workflow**
4. Optionally check **Force update** to update even if the version matches

## Local Development

To run the update script locally:

### Windows (PowerShell)
```powershell
.\scripts\update-packages.ps1

# With a specific version:
.\scripts\update-packages.ps1 -Version "13.6.0"

# Force update even if already at current version:
.\scripts\update-packages.ps1 -Force
```

### Linux/macOS
```bash
./scripts/update-packages.sh

# With a specific version:
./scripts/update-packages.sh 13.6.0

# Force update:
FORCE_UPDATE=1 ./scripts/update-packages.sh
```

## Adding More Packages

To add additional Firebase packages, edit the package list in:

1. `.github/workflows/update-firebase.yml` - `FIREBASE_PACKAGES` env variable
2. `scripts/update-packages.sh` - `FIREBASE_PACKAGES` array
3. `scripts/update-packages.ps1` - `$FirebasePackages` array

Available Firebase packages from [Google's Unity Archive](https://developers.google.com/unity/archive#firebase):
- `com.google.firebase.ai-logic` - Firebase AI Logic
- `com.google.firebase.instance-id` - Firebase Instance ID (deprecated)
- And more...

## How It Works

Instead of downloading the full Firebase SDK zip file, this repository downloads individual `.tgz` packages directly from Google's registry:

```
https://dl.google.com/games/registry/unity/{package-name}/{package-name}-{version}.tgz
```

This approach is:
- **Faster** - Only downloads what you need
- **More reliable** - Individual package downloads are smaller
- **Always up-to-date** - Tracks official Google releases

## Troubleshooting

### Dependencies not resolving on Android/iOS

Make sure you have the External Dependency Manager installed and run:
- **Assets > External Dependency Manager > Android Resolver > Resolve**
- **Assets > External Dependency Manager > iOS Resolver > Resolve**

### Version conflicts

Ensure all Firebase packages are using the same version. Mix-and-match versions can cause runtime errors.

### Package not found

If Unity can't find the package:
1. Check that the git URL is correct
2. Ensure the `packages/` folder exists in this repository
3. Try refreshing packages in Unity (**Window > Package Manager > Refresh**)

### Git LFS issues

If you encounter issues with large files, ensure Git LFS is installed:
```bash
git lfs install
```

## License

This repository redistributes Firebase Unity SDK packages. All packages retain their original licenses:

- Firebase Unity SDK: [Apache License 2.0](https://github.com/firebase/firebase-unity-sdk/blob/main/LICENSE)
- External Dependency Manager: [Apache License 2.0](https://github.com/googlesamples/unity-jar-resolver/blob/master/LICENSE)

The automation scripts in this repository are provided under the MIT License.

## Related Links

- [Firebase Unity SDK](https://github.com/firebase/firebase-unity-sdk)
- [Firebase Unity Documentation](https://firebase.google.com/docs/unity/setup)
- [Google Unity Archive](https://developers.google.com/unity/archive)
- [External Dependency Manager](https://github.com/googlesamples/unity-jar-resolver)
