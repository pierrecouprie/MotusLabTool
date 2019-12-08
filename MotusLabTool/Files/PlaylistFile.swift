//
//  PlaylistFile.swift
//  MotusLabTool
//
//  Created by Pierre Couprie on 08/09/2019.
//  Copyright © 2019 Pierre Couprie. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

@objcMembers
class PlaylistFile: NSObject, NSCoding {
    var url: URL!
    var folderURL: URL!
    var id: String!
    var name: String!
    var duration: Float = 0
    
    struct PropertyKey {
        static let urlKey = "url"
        static let folderURLKey = "folderURL"
        static let idKey = "id"
        static let nameKey = "name"
        static let durationKey = "duration"
    }
    
    init(url: URL, folderURL: URL, id: String, name: String, duration: Float ) {
        super.init()
        self.url = url
        self.folderURL = folderURL
        self.id = id
        self.name = name
        self.duration = duration
    }
    
    required init(coder aDecoder: NSCoder) {
        self.url = aDecoder.decodeObject(forKey: PropertyKey.urlKey) as? URL
        self.folderURL = aDecoder.decodeObject(forKey: PropertyKey.folderURLKey) as? URL
        self.id = aDecoder.decodeObject(forKey: PropertyKey.idKey) as? String
        self.name = aDecoder.decodeObject(forKey: PropertyKey.nameKey) as? String
        self.duration = aDecoder.decodeFloat(forKey: PropertyKey.durationKey)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.url, forKey: PropertyKey.urlKey)
        aCoder.encode(self.folderURL, forKey: PropertyKey.folderURLKey)
        aCoder.encode(self.id, forKey: PropertyKey.idKey)
        aCoder.encode(self.name, forKey: PropertyKey.nameKey)
        aCoder.encode(self.duration, forKey: PropertyKey.durationKey)
    }
    
}
