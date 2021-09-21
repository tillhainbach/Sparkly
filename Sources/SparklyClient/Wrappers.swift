//
//  File.swift
//  
//
//  Created by Till Hainbach on 20.09.21.
//

import Foundation

///
public enum UpdateCheck {
  case checkUpdates
  case checkUpdatesInBackground
  case checkUpdateInformation
}

public struct Appcast: Equatable {
  public let items: [AppcastItem]

  public init(items: [AppcastItem]) {
    self.items = items
  }
}
public struct AppcastItem: Equatable {
  public init(
    versionString: String,
    displayVersionString: String?,
    fileURL: URL?,
    contentLength: UInt64,
    infoURL: URL?,
    isInformationOnlyUpdate: Bool,
    title: String?,
    dateString: String?,
    date: Date?,
    releaseNotesURL: URL?,
    itemDescription: String?,
    minimumSystemVersion: String?,
    maximumSystemVersion: String?,
    installationType: String?,
    phasedRolloutInterval: NSNumber?,
    propertiesDictionary: [AnyHashable: AnyHashable]
  ) {
    self.versionString = versionString
    self.displayVersionString = displayVersionString
    self.fileURL = fileURL
    self.contentLength = contentLength
    self.infoURL = infoURL
    self.isInformationOnlyUpdate = isInformationOnlyUpdate
    self.title = title
    self.dateString = dateString
    self.date = date
    self.releaseNotesURL = releaseNotesURL
    self.itemDescription = itemDescription
    self.minimumSystemVersion = minimumSystemVersion
    self.maximumSystemVersion = maximumSystemVersion
    self.installationType = installationType
    self.phasedRolloutInterval = phasedRolloutInterval
    self.propertiesDictionary = propertiesDictionary
  }

  public let versionString: String
  public let displayVersionString: String?
  public let fileURL: URL?
  public let contentLength: UInt64
  public let infoURL: URL?
  public let isInformationOnlyUpdate: Bool
  public let title: String?
  public let dateString: String?
  public let date: Date?
  public let releaseNotesURL: URL?
  public let itemDescription: String?
  public let minimumSystemVersion: String?
  public let maximumSystemVersion: String?
  public let installationType: String?
  public let phasedRolloutInterval: NSNumber?

  public let propertiesDictionary: [AnyHashable: AnyHashable]


}
