//
//  ContentViewModel.swift
//  EndpointsTestbed
//
//  Created by Alexander Kauer on 06.04.23.
//

import Foundation
import Endpoints

@MainActor
class ContentViewModel: ObservableObject {
    
    func someCall() {
        Task {
            let url = URL(string: "https://postman-echo.com")!
            let myClient = AnyClient(baseURL: url)
            let mySession = Session(with: myClient)
        }
    }
}
