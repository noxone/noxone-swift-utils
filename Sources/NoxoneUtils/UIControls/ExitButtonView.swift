//
//  ExitButtonView.swift
//
//  Created by Olaf Neumann on 01.06.22.
//
// https://github.com/joogps/ExitButton
//

import SwiftUI

@available(iOS 15, macOS 12.0, *)
public struct ExitButtonView: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
            Image(systemName: "xmark")
                .resizable()
                .scaledToFit()
                .font(Font.body.weight(.bold))
                .scaleEffect(0.416)
                .foregroundColor(Color(white: colorScheme == .dark ? 0.62 : 0.51))
        }
    }
}

struct ExitButtonView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExitButtonView()
                .previewLayout(.fixed(width: 100.0, height: 100.0))
                .previewDisplayName("Light Mode")
            ExitButtonView()
                .previewLayout(.fixed(width: 100.0, height: 100.0))
                .previewDisplayName("Dark Mode")
                .environment(\.colorScheme, .dark)
        }
    }
}
