//
//  example.swift
//  Harmony Haven
//
//  Created by Serhat Erdem on 1.03.2025.
//

import SwiftUI


import SwiftUI

struct ExampleView: View {
    @State private var name = ""

    var body: some View {
        ZStack {
            Text("Example")
                .font(.title)
                .zIndex(2)
                .foregroundColor(.red)
                .padding()
            
            Button("Click me"){
                print("clicked")
            }
            
            TextField("Enter your name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
              

            
        }
    }
}

#Preview {
    ExampleView()
}
