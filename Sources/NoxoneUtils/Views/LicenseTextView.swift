//
//  LicenseTextView.swift
//  mahjong-point-calculator
//
//  Created by Olaf Neumann on 27.05.23.
//

import SwiftUI

struct LicenseTextView: View {
    private let licenseText: String
    
    init(fileName: String) {
        if let path = Bundle.main.path(forResource: fileName, ofType: "license"), let licenseText = try? String(contentsOfFile: path) {
            self.licenseText = licenseText
        } else {
            licenseText = "Lizenz konnte nicht geladen werden."
        }
    }
    
    var body: some View {
        Text(licenseText)
            .multilineTextAlignment(.leading)
            .font(.custom("Courier New", size: 15))
    }
}

struct LicenseTextView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseTextView(fileName: "Allison")
    }
}
