//
//  File.swift
//
//
//  Created by Till Hainbach on 30.10.21.
//

#if DEBUG

import Foundation

extension AppcastItem {
  public static let mock: Self = .init(
    versionString: "1234",
    displayVersionString: "1.0",
    fileURL: nil,
    contentLength: 20,
    infoURL: nil,
    isInformationOnlyUpdate: false,
    title: "Update",
    dateString: "2021-10-30",
    date: Date(timeIntervalSince1970: 1_635_552_000),
    releaseNotesURL: nil,
    itemDescription: nil,
    minimumSystemVersion: nil,
    maximumSystemVersion: nil,
    installationType: nil,
    phasedRolloutInterval: nil,
    propertiesDictionary: [:]
  )
}

extension UserUpdateState {
  public static let mock = Self(stage: .notDownloaded, userInitiated: true)
}

extension DownloadData {
  public static let mock = Self(
    data: "New Update".data(using: .utf8)!,
    url: URL(string: "https://tillhainbach.github.io/Sparkly/")!,
    textEncodingName: nil,
    mimeType: nil
  )
}

#endif
