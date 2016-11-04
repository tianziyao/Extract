//
//  GifView.swift
//  GifForMACDev
//
//  Created by 田子瑶 on 16/11/4.
//  Copyright © 2016年 田子瑶. All rights reserved.
//

import Cocoa

class GifView: NSView {

    var image: NSImage!
    var gifBitmapRep: NSBitmapImageRep!
    var currentFrameIdx: NSInteger!
    var timer: Timer!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.drawGif()
        
    }
    
    func setImage(withUrl url: String) {
        
        var request = URLRequest(url: URL.init(string: url)!)
        request.addValue("image/*", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { (data, resp, error) in
            
            guard error == nil || data == nil else {
                Swift.print("请求错误或请求数据为空")
                return
            }
            
            let image = NSImage(data: data!)
            self.setImage(withImage: image!)
        }
        
        task.resume()
    }
    
    func setImage(withImage image: NSImage) {
        
        self.image = image
        self.gifBitmapRep = nil
        
        if self.timer != nil {
            self.timer.invalidate()
            self.timer = nil
        }
        
        let reps = self.image.representations
        
        for rep in reps {
            let rep = rep as! NSBitmapImageRep
            let numFrame = rep.value(forProperty: NSImageFrameCount) as! Int
            if numFrame == 0 {
                break
            }
            let delayTime = rep.value(forProperty: NSImageCurrentFrameDuration) as! TimeInterval
            self.currentFrameIdx = 0
            self.gifBitmapRep = rep
            self.timer = Timer(timeInterval: delayTime / 3,
                               target: self,
                               selector: #selector(GifView.animateGif),
                               userInfo: nil,
                               repeats: true)
        }
        
        RunLoop.main.add(self.timer, forMode: .commonModes)
    }
    
    func animateGif() {
        self.needsDisplay = true
    }
    
    func drawGif() {
        
        if self.gifBitmapRep != nil {
            
            let numFrame = gifBitmapRep.value(forProperty: NSImageFrameCount) as! NSInteger
            
            if self.currentFrameIdx >= numFrame {
                self.currentFrameIdx = 0
            }
            
            self.gifBitmapRep.setProperty(NSImageCurrentFrame, withValue: self.currentFrameIdx)
            
            let selfHeight = self.frame.size.height
            let selfWidth = self.frame.size.width
            
            let imageHeight = self.image.size.height
            let imageWidth = self.image.size.width
            
            var drawGifRect = NSRect()
            
            if self.image.size.width > self.frame.size.width || self.image.size.height > self.frame.size.height {

                let newWidth = imageWidth / 1.7
                let newHeight = imageHeight / 1.7
                drawGifRect = NSRect(x: (selfWidth - newWidth) / 2,
                                     y: (selfHeight - newHeight) / 2,
                                     width: newWidth,
                                     height: newHeight)
            }
            else {
                drawGifRect = NSRect(x: (selfWidth - imageWidth) / 2,
                                     y: (selfHeight - imageWidth) / 2,
                                     width: imageWidth,
                                     height: imageHeight)
            }
            self.gifBitmapRep.draw(in: drawGifRect,
                                   from: NSZeroRect,
                                   operation: .sourceOver,
                                   fraction: 1.0,
                                   respectFlipped: false,
                                   hints: nil)
            
            self.currentFrameIdx! += 1
            
        }
    
    }
    
}
