# KompanTokens

KOMPAN design tokens for iOS. **Generated — do not edit.** Every file here is
produced by `@kompan-design/token-build` from the design system release of the
same version, and this repository is rewritten on each release.

Current version: `0.6.1`.

## Install

```swift
.package(url: "https://github.com/wah-kompan/kompan-tokens-swift.git", from: "0.6.1")
```

Then add `KompanTokens` to your target's dependencies.

## Use

```swift
import KompanTokens

view.backgroundColor = Tokens.colorModeSectionsBranchBackgroundBgPrimary
```

Gradients and shadows carry structured values rather than a single colour — see
`TokenSupport.swift` for the types they resolve to.

## Versioning

Tags match the design system release exactly and are never moved. Upgrading is a
deliberate change to the version in your `Package.swift`.
