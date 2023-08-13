//
//  SwiftUIView.swift
//  
//
//  Created by Olaf Neumann on 09.08.23.
//

//

import SwiftUI

public struct CloseableView<Content: View>: View {
    @Environment(\.dismiss) var dismiss
    @ScaledMetric(relativeTo: .body) private var buttonSize: CGFloat = 42
    
    var imageName: String? = nil
    var imageSize: CGFloat = 200
    var content: () -> Content
    
    public init(imageName: String? = nil, imageSize: CGFloat = 200, content: @escaping () -> Content) {
        self.imageName = imageName
        self.imageSize = imageSize
        self.content = content
    }
    
    public var body: some View {
        ScrollView {
            if let imageName {
                ZStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: imageSize)
                        .clipped()
                
                    LinearGradient(gradient: Gradient(colors: [.clear, Color(uiColor: UIColor.systemBackground)]), startPoint: .top, endPoint: .bottom)
                        .frame(height: imageSize * 0.5)
                        .padding(.top, imageSize * 0.5)
                }
            }
            
            content()
                .padding(.horizontal)
        }
        .ignoresSafeArea(edges: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                dismiss()
            }, label: {
                Label {
                    Text("Dismiss")
                } icon: {
                    ExitButtonView()
                        .frame(width: buttonSize, height: buttonSize)
                }
                .padding()
            })
            .labelStyle(.iconOnly)
            .accessibilityElement()
            
        }
    }
}

struct CloseableView_Previews: PreviewProvider {
    static var previews: some View {
        CloseableView(imageName: "AppBackground") {
            Text("abc")
        }
    }
}
