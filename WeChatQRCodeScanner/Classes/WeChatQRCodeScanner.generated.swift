//
// This is a generated file, do not edit!
// Generated by R.swift, see https://github.com/mac-cain13/R.swift
//

import Foundation
import Rswift

/// This `R` struct is generated and contains references to static resources.
struct R: Rswift.Validatable {
  fileprivate static let applicationLocale = hostingBundle.preferredLocalizations.first.flatMap { Locale(identifier: $0) } ?? Locale.current
  fileprivate static let hostingBundle = Bundle.codeScanner

  /// Find first language and bundle for which the table exists
  fileprivate static func localeBundle(tableName: String, preferredLanguages: [String]) -> (Foundation.Locale, Foundation.Bundle)? {
    // Filter preferredLanguages to localizations, use first locale
    var languages = preferredLanguages
      .map { Locale(identifier: $0) }
      .prefix(1)
      .flatMap { locale -> [String] in
        if hostingBundle.localizations.contains(locale.identifier) {
          if let language = locale.languageCode, hostingBundle.localizations.contains(language) {
            return [locale.identifier, language]
          } else {
            return [locale.identifier]
          }
        } else if let language = locale.languageCode, hostingBundle.localizations.contains(language) {
          return [language]
        } else {
          return []
        }
      }

    // If there's no languages, use development language as backstop
    if languages.isEmpty {
      if let developmentLocalization = hostingBundle.developmentLocalization {
        languages = [developmentLocalization]
      }
    } else {
      // Insert Base as second item (between locale identifier and languageCode)
      languages.insert("Base", at: 1)

      // Add development language as backstop
      if let developmentLocalization = hostingBundle.developmentLocalization {
        languages.append(developmentLocalization)
      }
    }

    // Find first language for which table exists
    // Note: key might not exist in chosen language (in that case, key will be shown)
    for language in languages {
      if let lproj = hostingBundle.url(forResource: language, withExtension: "lproj"),
         let lbundle = Bundle(url: lproj)
      {
        let strings = lbundle.url(forResource: tableName, withExtension: "strings")
        let stringsdict = lbundle.url(forResource: tableName, withExtension: "stringsdict")

        if strings != nil || stringsdict != nil {
          return (Locale(identifier: language), lbundle)
        }
      }
    }

    // If table is available in main bundle, don't look for localized resources
    let strings = hostingBundle.url(forResource: tableName, withExtension: "strings", subdirectory: nil, localization: nil)
    let stringsdict = hostingBundle.url(forResource: tableName, withExtension: "stringsdict", subdirectory: nil, localization: nil)

    if strings != nil || stringsdict != nil {
      return (applicationLocale, hostingBundle)
    }

    // If table is not found for requested languages, key will be shown
    return nil
  }

  /// Load string from Info.plist file
  fileprivate static func infoPlistString(path: [String], key: String) -> String? {
    var dict = hostingBundle.infoDictionary
    for step in path {
      guard let obj = dict?[step] as? [String: Any] else { return nil }
      dict = obj
    }
    return dict?[key] as? String
  }

  static func validate() throws {
    try intern.validate()
  }

  /// This `R.file` struct is generated, and contains static references to 4 files.
  struct file {
    /// Resource file `detect.caffemodel`.
    static let detectCaffemodel = Rswift.FileResource(bundle: R.hostingBundle, name: "detect", pathExtension: "caffemodel")
    /// Resource file `detect.prototxt`.
    static let detectPrototxt = Rswift.FileResource(bundle: R.hostingBundle, name: "detect", pathExtension: "prototxt")
    /// Resource file `sr.caffemodel`.
    static let srCaffemodel = Rswift.FileResource(bundle: R.hostingBundle, name: "sr", pathExtension: "caffemodel")
    /// Resource file `sr.prototxt`.
    static let srPrototxt = Rswift.FileResource(bundle: R.hostingBundle, name: "sr", pathExtension: "prototxt")

    /// `bundle.url(forResource: "detect", withExtension: "caffemodel")`
    static func detectCaffemodel(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.detectCaffemodel
      return fileResource.bundle.url(forResource: fileResource)
    }

    /// `bundle.url(forResource: "detect", withExtension: "prototxt")`
    static func detectPrototxt(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.detectPrototxt
      return fileResource.bundle.url(forResource: fileResource)
    }

    /// `bundle.url(forResource: "sr", withExtension: "caffemodel")`
    static func srCaffemodel(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.srCaffemodel
      return fileResource.bundle.url(forResource: fileResource)
    }

    /// `bundle.url(forResource: "sr", withExtension: "prototxt")`
    static func srPrototxt(_: Void = ()) -> Foundation.URL? {
      let fileResource = R.file.srPrototxt
      return fileResource.bundle.url(forResource: fileResource)
    }

    fileprivate init() {}
  }

  fileprivate struct intern: Rswift.Validatable {
    fileprivate static func validate() throws {
      // There are no resources to validate
    }

    fileprivate init() {}
  }

  fileprivate class Class {}

  fileprivate init() {}
}

struct _R {
  fileprivate init() {}
}
