//
//  PUDynamicQRCodeView.swift
//  PeixeUrbanoKit
//
//  Created by Guilherme Rambo on 28/03/19.
//

import Cocoa
import os.log

class PUDynamicQRCodeView: NSView {

    private let log = OSLog(subsystem: "QRCode", category: "PUDynamicQRCodeView")

    /// The string with the payload to be used to generate the code
    public var payload: String? {
        didSet {
            generateImage()
        }
    }

    private(set) lazy var imageView: NSImageView = {
        let v = NSImageView()

        v.imageScaling = .scaleProportionallyUpOrDown
        v.autoresizingMask = [.width, .height]

        return v
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.frame = bounds
        addSubview(imageView)
    }

    private let dispatchQueue = DispatchQueue(label: "QRCodeGen", qos: .userInteractive)

    private lazy var generator = CIFilter(name: "CIQRCodeGenerator")

    private func generateImage() {
        guard let payload = payload,
            let generator = generator,
            let data = payload.data(using: .isoLatin1, allowLossyConversion: false)
            else {
                os_log("QR payload preparation failed", log: self.log, type: .fault)
                return
        }

        dispatchQueue.async { [weak self] in
            guard let self = self else { return }

            generator.setValue(data, forKey: "inputMessage")

            guard let outputImage = generator.outputImage else {
                os_log("Failed to generate QR code image", log: self.log, type: .fault)
                return
            }

            let transformed = outputImage.transformed(by: CGAffineTransform.init(scaleX: 30, y: 30))

            guard let invertFilter = CIFilter(name: "CIColorInvert") else {
                os_log("Failed to create invert filter", log: self.log, type: .fault)
                return
            }

            invertFilter.setValue(transformed, forKey: kCIInputImageKey)

            let alphaFilter = CIFilter(name: "CIMaskToAlpha")

            alphaFilter?.setValue(invertFilter.outputImage, forKey: kCIInputImageKey)

            guard let finalImage = alphaFilter?.outputImage else {
                os_log("Failed to generate final image", log: self.log, type: .fault)
                return
            }

            DispatchQueue.main.async {
                let rep = NSCIImageRep(ciImage: finalImage)

                let image = NSImage(size: rep.size)
                image.addRepresentation(rep)

                self.imageView.image = image
            }
        }
    }

}
