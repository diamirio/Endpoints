//
//  FakeResultProvider.swift
//  Endpoints
//
//  Created by Robin Mayerhofer on 27.08.19.
//  Copyright © 2019 Tailored Apps. All rights reserved.
//

import Foundation

public protocol FakeResultProvider {
    func resultFor<C: Call>(call: C) -> URLSessionTaskResult
}
