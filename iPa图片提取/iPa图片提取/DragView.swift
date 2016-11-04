//
//  DragView.swift
//  iPa图片提取
//
//  Created by 田子瑶 on 16/10/31.
//  Copyright © 2016年 田子瑶. All rights reserved.
//

import Cocoa


protocol DragViewDelegate {
    func dragView(dragView: DragView, didDragItems items: [String])
}

class DragView: NSView {
    
    private var enable: Bool = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        dragEnable = false
        self.dragEnable = true
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        //fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置是否使用文件拖放
    var dragEnable: Bool {
        
        set {
            if !newValue {
                //  关闭文件拖放
                self.unregisterDraggedTypes()
            }
            else {
                //  开启文件拖放
                self.register(forDraggedTypes: [NSFilenamesPboardType])
            }
            self.enable = newValue
        }

        get {
            return self.enable
        }
    }
    
    /// 接收到拖拽文件后回调
    var delegate: DragViewDelegate!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        dragEnable = false
        self.dragEnable = true

    }
    
    func notificationPost(eventName: String, dict: [String : String]) {
        let notification = Notification(name: NSNotification.Name(rawValue: eventName),
                                        object: nil,
                                        userInfo: dict)
        NotificationCenter.default.post(notification)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        notificationPost(eventName: "updataForStatusLabel", dict: ["title" : "停止拖放以继续"])
        dragEnable = true
        self.needsDisplay = true
        return NSDragOperation.copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        notificationPost(eventName: "updataForStatusLabel", dict: ["title" : "拖拽文件到这里"])
        dragEnable = false
        self.needsDisplay = true
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        dragEnable = false
        self.needsDisplay = true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        
        let pasteboard = sender.draggingPasteboard()
        
        if (pasteboard.types?.contains(NSFilenamesPboardType))! {
            let items = pasteboard.propertyList(forType: NSFilenamesPboardType)
            self.delegate.dragView(dragView: self, didDragItems: items as! [String])
            return true
        }
        return false
    }
    
    
    
}



