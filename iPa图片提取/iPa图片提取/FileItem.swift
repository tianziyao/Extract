//
//  FileItem.swift
//  iPa图片提取
//
//  Created by 田子瑶 on 16/10/31.
//  Copyright © 2016年 田子瑶. All rights reserved.
//

import Cocoa

class FileItem: NSObject {
    
    private var path: String!
    
    /// 文件路径
    var filePath: String {
        set {
            path = newValue
            isFileExists = FileManager.default.fileExists(atPath: newValue, isDirectory: &isDirectory)
        }
        get {
            return path
        }
    }
    
    /// 文件(夹)名称
    var fileName: String {
        return (filePath as NSString).lastPathComponent
    }
    
    /// 是否是文件夹
    var isDirectory: ObjCBool = false
    
    /// 是否存在
    var isFileExists: Bool!
    
    /// 工厂方法
    ///
    /// - parameter withPath: 文件路径
    ///
    /// - returns: 模型实例
    class func fileItem(withPath: String) -> FileItem {
        let fileItem = FileItem()
        fileItem.filePath = withPath
        return fileItem
    }
    
}
