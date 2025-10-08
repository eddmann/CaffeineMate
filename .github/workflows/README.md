# GitHub Actions Workflows

## Release Workflow

The `release.yml` workflow allows you to build and release CaffeineMate directly from GitHub.

### How to Use

1. **Go to GitHub Actions tab** in your repository
2. **Select "Release CaffeineMate"** from the workflows list
3. **Click "Run workflow"** button
4. **Enter the version number** (e.g., `1.0.0`, `1.1.0`, `2.0.0-beta`)
5. **Click "Run workflow"** to start the build

### What It Does

1. ✅ Checks out your code
2. ✅ Updates version numbers in the Xcode project
3. ✅ Builds the app for Release
4. ✅ Creates a ZIP file of the app
5. ✅ Creates a GitHub Release with the version tag
6. ✅ Uploads the app as a release asset
7. ✅ Generates release notes automatically

### Version Format

Use semantic versioning: `MAJOR.MINOR.PATCH`

- **1.0.0** - First release
- **1.1.0** - New features
- **1.0.1** - Bug fixes
- **2.0.0** - Breaking changes

You can also use pre-release tags:
- **1.0.0-beta.1**
- **1.0.0-rc.1**

### Code Signing (Optional)

The current workflow builds **unsigned** apps. Users will need to right-click and select "Open" the first time.

#### To Enable Code Signing:

1. **Get an Apple Developer Account** ($99/year)
2. **Create a Developer ID Application certificate** in Xcode
3. **Export the certificate** to a `.p12` file
4. **Add GitHub Secrets**:
   - Go to repository Settings → Secrets and variables → Actions
   - Add these secrets:
     - `DEVELOPER_ID_APPLICATION_CERT` - Base64-encoded .p12 file
     - `DEVELOPER_ID_APPLICATION_PASSWORD` - Certificate password
     - `APPLE_ID` - Your Apple ID email
     - `APPLE_ID_PASSWORD` - App-specific password
     - `APPLE_TEAM_ID` - Your team ID

5. **Update the workflow**:
   ```yaml
   - name: Import certificates
     run: |
       # Create keychain
       security create-keychain -p actions temp.keychain
       security default-keychain -s temp.keychain
       security unlock-keychain -p actions temp.keychain

       # Import certificate
       echo "${{ secrets.DEVELOPER_ID_APPLICATION_CERT }}" | base64 --decode > cert.p12
       security import cert.p12 -k temp.keychain -P "${{ secrets.DEVELOPER_ID_APPLICATION_PASSWORD }}" -T /usr/bin/codesign
       security set-key-partition-list -S apple-tool:,apple: -s -k actions temp.keychain

   - name: Build app (signed)
     run: |
       xcodebuild clean build \
         -project CaffeineMate.xcodeproj \
         -scheme CaffeineMate \
         -configuration Release \
         -derivedDataPath ./build \
         CODE_SIGN_IDENTITY="Developer ID Application" \
         CODE_SIGN_STYLE=Manual

   - name: Notarize app
     run: |
       cd build/Build/Products/Release
       ditto -c -k --keepParent CaffeineMate.app CaffeineMate.zip
       xcrun notarytool submit CaffeineMate.zip \
         --apple-id "${{ secrets.APPLE_ID }}" \
         --password "${{ secrets.APPLE_ID_PASSWORD }}" \
         --team-id "${{ secrets.APPLE_TEAM_ID }}" \
         --wait
       xcrun stapler staple CaffeineMate.app
   ```

### Troubleshooting

**Build fails with "No signing certificate"**
- This is expected for unsigned builds - the workflow disables signing
- To enable signing, follow the "Code Signing" instructions above

**Release already exists**
- Delete the existing release and tag from GitHub
- Or use a different version number

**App won't open on macOS**
- Right-click the app and select "Open"
- This is required for unsigned apps

**Workflow doesn't appear**
- Make sure the workflow file is in `.github/workflows/`
- Push the workflow file to GitHub
- Check the Actions tab for any errors

### Manual Release (Alternative)

If you prefer to build locally:

```bash
# Build
xcodebuild clean build \
  -project CaffeineMate.xcodeproj \
  -scheme CaffeineMate \
  -configuration Release \
  -derivedDataPath ./build

# Create ZIP
cd build/Build/Products/Release
zip -r CaffeineMate.zip CaffeineMate.app

# Upload to GitHub Releases manually
```
