//
//  MediaAsset.swift
//  media_picker_builder
//
//  Created by Juan Alvarez on 10/19/20.
//

import Foundation

struct MediaAsset: Codable {
    let id: String
    let dateAdded: Int // seconds since 1970
    let orientation: Int
    let duration: Double?
    let type: MediaType
}
