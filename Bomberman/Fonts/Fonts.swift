//
//  Fonts.swift
//  Bomberman
//
//  Created by лизо4ка курунок on 09.12.2025.
//

import UIKit

enum Fonts {
    static let pixelHeading = UIFont(name: "AwesomePixels-Yellow", size: 60) ?? UIFont.systemFont(ofSize: 60)
    static let pixel27 = UIFont(name: "PixelifySans-Regular", size: 27) ?? UIFont.systemFont(ofSize: 27)
    static func pixelify(_ size: CGFloat) -> UIFont {
        UIFont(name: "PixelifySans-Regular", size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
}
