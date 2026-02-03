//
//  ContentView.swift
//  PlainPad
//
//  Created by Lance Eaton on 2/3/26.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: PlainPadDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(PlainPadDocument()))
}
