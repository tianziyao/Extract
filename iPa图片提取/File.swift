//
//  File.swift
//  iPa图片提取
//
//  Created by 田子瑶 on 16/11/5.
//  Copyright © 2016年 田子瑶. All rights reserved.
//

import Foundation
import AppKit

extension NSAttributedString {
    
    class func hyperlinkFromString(inString: String, withURL url: URL) -> NSAttributedString {
        let attrString = NSMutableAttributedString(string: inString)
        let range = NSMakeRange(0, attrString.length)
        attrString.beginEditing()
        attrString.addAttribute(NSLinkAttributeName, value: url.absoluteString, range: range)
        attrString.addAttribute(NSForegroundColorAttributeName, value: NSColor.blue, range: range)
        let num = NSNumber.init(value: NSUnderlineStyle.styleSingle.rawValue)
        attrString.addAttribute(NSUnderlineStyleAttributeName, value: num, range: range)
        attrString.endEditing()
        return attrString
    }
}
