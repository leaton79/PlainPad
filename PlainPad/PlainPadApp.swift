//
//  PlainPadApp.swift
//  PlainPad
//
//  Created by Lance Eaton on 2/3/26.
//

import SwiftUI

@main
struct PlainPadApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: PlainPadDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
