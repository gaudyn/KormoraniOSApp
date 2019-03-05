//
//  Kormoran_Beach_Party_Tests.swift
//  Kormoran Beach Party Tests
//
//  Created by Administrator on 03/03/2019.
//  Copyright © 2019 Kormoran Beach Party Sekcja Informatyczna. All rights reserved.
//

import XCTest

@testable import Kormoran_Beach_Party

class Kormoran_Beach_Party_Tests: XCTestCase {

    func test(){
        let api = API()
        XCTAssertTrue(api.checkConnection(), "Hello")
    }

}
