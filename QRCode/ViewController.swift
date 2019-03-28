//
//  ViewController.swift
//  QRCode
//
//  Created by Guilherme Rambo on 28/03/19.
//  Copyright © 2019 Guilherme Rambo. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var codeView: PUDynamicQRCodeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(hue: 0.58, saturation: 1.00, brightness: 0.79, alpha: 1.00).cgColor

        codeView.payload = UserDefaults.standard.string(forKey: "QRCode") ?? "Peixe Urbano"
    }

    @IBAction func customizeCode(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Customize code"
        alert.informativeText = "Enter the QR Code to be generated."

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = field

        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let button = alert.runModal()

        if button == .alertFirstButtonReturn {
            field.validateEditing()
            codeView.payload = field.stringValue
        }
    }

    @IBAction func saveDocument(_ sender: Any?) {
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["tiff"]

        panel.runModal()

        guard let url = panel.url else { return }

        guard let invertFilter = CIFilter(name: "CIColorInvert") else {
            NSLog("Invert error")
            return
        }

        guard let tif = codeView.imageView.image?.tiffRepresentation else {
            NSLog("No tif")
            return
        }

        guard let image = CIImage(data: tif) else {
            NSLog("No CIImage")
            return
        }

        invertFilter.setValue(image, forKey: kCIInputImageKey)

        guard let invertedImage = invertFilter.outputImage else {
            NSLog("No inverted image")
            return
        }

        let rep = NSCIImageRep(ciImage: invertedImage)

        let outImage = NSImage(size: rep.size)
        outImage.addRepresentation(rep)

        guard let outTif = outImage.tiffRepresentation else {
            NSLog("No out tif")
            return
        }

        do {
            try outTif.write(to: url)
        } catch {
            NSLog("Error saving: \(error)")
        }
    }


}

