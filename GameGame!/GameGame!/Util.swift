//
//  Util.swift
//  GameGame!
//
//  Created by VincentHe on 7/4/16.
//  Copyright © 2016 com.Changchen. All rights reserved.
//

import UIKit

class Util: NSObject {
    static func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
}
