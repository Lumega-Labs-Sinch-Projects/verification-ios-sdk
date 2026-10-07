# HDFC handoff — Option C (Local-path CocoaPods)

This guide is for Sinch engineers packaging and sharing an updated **Sinch Verification iOS SDK** with HDFC using **Option C**: a self-contained source folder + podspec, integrated via local CocoaPods path (no Git access, no prebuilt XCFramework).

Use this when delivering the **iOS 27 Release seamless fix** (`HTTPRequester` response buffer) or any later source drop.

---

## 1. What Option C is

| Item | Detail |
|---|---|
| Delivery | Zip/folder of SDK **source** + `SinchVerificationSDK.podspec` |
| Client integration | `pod 'SinchVerificationSDK', :path => 'Vendor/SinchVerificationSDK'` |
| Build | Client compiles from source with their Xcode/Swift toolchain |
| Repo URL | **Not** required; fork/Git URL is not exposed |

---

## 2. Prerequisites (Sinch side)

- Access to branch with the fix, e.g.  
  `fix/httprequester-release-buffer`  
  (commit: *Fix seamless Release failure decoding cellular HTTP responses*)
- Remote (if needed):  
  `https://github.com/Lumega-Labs-Sinch-Projects/verification-ios-sdk`  
  branch `fix/httprequester-release-buffer`
- macOS with Git; optional: zip / Finder

Do **not** include Pods, DerivedData, `.git` history with private remotes, sample keys, or internal docs unless approved.

---

## 3. Package the folder (Sinch)

### 3.1 Check out the patched code

```bash
git clone https://github.com/Lumega-Labs-Sinch-Projects/verification-ios-sdk.git
cd verification-ios-sdk
git checkout fix/httprequester-release-buffer
```

Confirm the fix is present:

```bash
grep -n "responseLength" Verification/Verification/Classes/NetworkingLogic/HTTPRequester.m
```

You should see lines that set and use `responseLength` (not `length:sizeof(buffer)` for the response `NSString`).

### 3.2 Create the Vendor package directory

From the repo root, create a clean package (name can match what you tell HDFC):

```bash
EXPORT_DIR="SinchVerificationSDK-HDFC-$(date +%Y%m%d)"
mkdir -p "../${EXPORT_DIR}"

# Required for Option C CocoaPods path
cp SinchVerificationSDK.podspec "../${EXPORT_DIR}/"

# SDK sources referenced by the podspec
mkdir -p "../${EXPORT_DIR}/Verification/Verification"
cp -R Verification/Verification/Classes "../${EXPORT_DIR}/Verification/Verification/"

# License (recommended)
cp LICENSE.txt "../${EXPORT_DIR}/" 2>/dev/null || true
```

Optional but recommended — set a clear drop version in the copied podspec so HDFC can identify the build:

Edit `../${EXPORT_DIR}/SinchVerificationSDK.podspec`:

```ruby
spec.version = "3.3.2"   # matches SinchVerificationSDK.podspec for this drop
```

Leave `spec.source_files` as:

```ruby
spec.source_files  = "Verification/Verification/Classes", "Verification/Verification/Classes/**/*.{h,m,c,swift}"
spec.exclude_files = "Verification/Verification/Classes/Exclude"
```

Dependencies stay as in the podspec (client resolves via CocoaPods):

- Alamofire `~> 5.2`
- ReachabilitySwift
- PhoneNumberKit/PhoneNumberKitCore `~> 3.1`
- SwiftyBeaver `~> 2.0`

iOS deployment target in podspec should be **15.0** (or whatever is agreed).

### 3.3 Verify package layout

```text
SinchVerificationSDK-HDFC-YYYYMMDD/
├── SinchVerificationSDK.podspec
├── LICENSE.txt                          (optional)
└── Verification/
    └── Verification/
        └── Classes/
            ├── ...
            └── NetworkingLogic/
                └── HTTPRequester.m      ← must contain responseLength fix
```

### 3.4 Sanity-check podspec locally (optional)

```bash
cd "../${EXPORT_DIR}"
pod spec lint SinchVerificationSDK.podspec --quick --allow-warnings
```

### 3.5 Zip and hand over

```bash
cd ..
zip -r "${EXPORT_DIR}.zip" "${EXPORT_DIR}"
```

Share **`${EXPORT_DIR}.zip`** with HDFC via the agreed secure channel (email / portal / SFTP).  
Include a short note: *Option C local-path CocoaPods; includes iOS 27 Release seamless fix.*

---

## 4. What to tell HDFC (client steps)

Copy/adapt the following for the HDFC integration team.

### 4.1 Place the SDK in their app repo

1. Unzip the package.
2. Copy the folder into their iOS project, e.g.:

```text
TheirApp/
├── Podfile
├── TheirApp/
└── Vendor/
    └── SinchVerificationSDK/          ← contents of the zip (podspec at this root)
        ├── SinchVerificationSDK.podspec
        └── Verification/
            └── Verification/
                └── Classes/
```

### 4.2 Podfile

```ruby
platform :ios, '15.0'   # or their app minimum, ≥ podspec
use_frameworks!

target 'TheirApp' do
  pod 'SinchVerificationSDK', :path => 'Vendor/SinchVerificationSDK'
end
```

Then:

```bash
pod install
```

Open the **`.xcworkspace`**, not the `.xcodeproj`.

### 4.3 Build configuration note (important for this fix)

The seamless bug showed up in **Release** on **iOS 27**. After integrating Option C:

1. Build **Release** (or Archive / TestFlight-like config), not only Debug.
2. Test seamless on a **physical device with cellular data** (Wi‑Fi off recommended).
3. Confirm success where previously they saw:  
   `Error when executing HTTP requests`.

### 4.4 Updates later

New drops = new zip/folder. Replace `Vendor/SinchVerificationSDK` and run `pod install` again. There is no Git tag to bump for Option C.

---

## 5. Checklist before sending to HDFC

- [ ] Package built from branch that contains the `HTTPRequester` `responseLength` fix  
- [ ] `grep responseLength …/HTTPRequester.m` succeeds in the **packaged** folder  
- [ ] `SinchVerificationSDK.podspec` present at package root  
- [ ] Source tree matches podspec `source_files` paths  
- [ ] No `.git` folder with internal remotes (optional: omit `.git` entirely)  
- [ ] No `Pods/`, DerivedData, or sample app secrets  
- [ ] Version string in podspec updated for this drop (recommended)  
- [ ] Zip tested once: empty Xcode sample + `:path` Podfile + `pod install` + Release build  

---

## 6. Quick comparison (for context)

| Aspect | A: XCFramework | B: Git CocoaPods | **C: Local-path (this doc)** |
|---|---|---|---|
| Client needs CocoaPods | No | Yes | **Yes** |
| Client needs repo/Git access | No | Yes | **No** |
| Fork URL exposed | No | Yes | **No** |
| Compiles with client toolchain | No | Yes | **Yes** |
| What we deliver | Binaries | Commit/tag | **Source folder/zip** |

---

## 7. Internal reference

| Item | Value |
|---|---|
| Fix branch | `fix/httprequester-release-buffer` |
| SDK version | `3.3.2` |
| iOS deployment target | `15.0` |
| Fix commit (example) | `cb5baa0` — Fix seamless Release failure decoding cellular HTTP responses |
| Symptom fixed | Release + iOS 27 seamless → `Error when executing HTTP requests` |
| Root cause | `HTTPRequester` decoded `sizeof(buffer)` instead of bytes actually received |
| Validation | Patched Release succeeded on iOS 27.0.1 and iOS 26.6.2 physical devices |

---

## 8. Support line for HDFC email (optional)

> Please integrate using Option C (local-path CocoaPods) as previously discussed. Unzip the attached SDK folder under `Vendor/SinchVerificationSDK` and add  
> `pod 'SinchVerificationSDK', :path => 'Vendor/SinchVerificationSDK'`  
> then run `pod install`. This drop includes a fix for seamless verification failing in **Release** builds on **iOS 27**. Please verify on a physical device with cellular data using a Release/Archive build.
