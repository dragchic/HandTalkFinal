//
//  AnimatedGIFView.swift
//  HandTalk
//
//  Created by William on 19/06/25.
//

import SwiftUI
import UIKit
import ImageIO

struct AnimatedGIFView: UIViewRepresentable {
    let gifName: String

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let imageView = UIImageView()

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = true
        
        container.addSubview(imageView)

        // Constrain the imageView to fill the container
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: container.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        // Load GIF
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            imageView.image = UIImage.animatedImageWithGIFData(data)
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}


// UIImage extension to handle GIF data
extension UIImage {
    static func animatedImageWithGIFData(_ data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        var images: [UIImage] = []
        var duration: Double = 0

        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let delaySeconds = UIImage.delayForImageAtIndex(i, source: source)
                duration += delaySeconds
                images.append(UIImage(cgImage: cgImage))
            }
        }

        return UIImage.animatedImage(with: images, duration: duration)
    }

    private static func delayForImageAtIndex(_ index: Int, source: CGImageSource) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
              let delayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
        else { return 0.1 }

        return delayTime < 0.01 ? 0.1 : delayTime
    }
}
