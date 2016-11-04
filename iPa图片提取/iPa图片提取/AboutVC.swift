//
//  AboutVC.swift
//  iPa图片提取
//
//  Created by 田子瑶 on 16/11/5.
//  Copyright © 2016年 田子瑶. All rights reserved.
//

import Cocoa

class AboutVC: NSViewController {


    @IBOutlet weak var archive: NSTextField!
    @IBOutlet weak var extractor: NSTextField!
    @IBOutlet weak var email: NSTextField!
    @IBOutlet weak var homePage: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLabelTitle(label: extractor, title: "iOS-Asset-Extractor", url: "https://github.com/Marxon13/iOS-Asset-Extractor")
        setLabelTitle(label: archive, title: "ZipArchive ", url: "https://github.com/mattconnolly/ZipArchive")
        let emailUrl = "mailto:ziyao.tian@gmail.com?subject=About%20Extract.app&body=Hi"
        setLabelTitle(label: email, title: "ziyao.tian@gmail.com", url: emailUrl)
        setLabelTitle(label: homePage, title: "github.com/tianziyao", url: "https://github.com/tianziyao")
    }
    
    func setLabelTitle(label: NSTextField, title: String, url: String) {
        
                label.allowsEditingTextAttributes = true
                label.isSelectable = true
                let url = URL(string: url)
                let string = NSMutableAttributedString()
                string.append(NSAttributedString.hyperlinkFromString(inString: title, withURL: url!))
                label.attributedStringValue = string
    }
    
    @IBAction func backButtonClicked(_ sender: AnyObject) {
        self.dismiss(self)
    }

}
