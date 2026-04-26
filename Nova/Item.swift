//
//  Item.swift
//  Nova
//
//  Created by Alex Lam on 26/4/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
