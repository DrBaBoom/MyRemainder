//
//  Note.swift
//  MyRemainder
//
//  Created by Yura on 21.09.2023.
//

import Foundation
import RealmSwift


class Note: Object {
    @Persisted(primaryKey: true)
    var _id: ObjectId
    
    @Persisted
    var text: String = ""
    
    @Persisted
    var n1: Int? = nil
    
    @Persisted
    var n2: Int? = nil
    
    @Persisted
    var isOn: Bool = true
}
