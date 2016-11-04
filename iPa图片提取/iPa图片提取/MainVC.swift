//
//  ViewController.swift
//  iPa图片提取
//
//  Created by 田子瑶 on 16/10/31.
//  Copyright © 2016年 田子瑶. All rights reserved.
//

import Cocoa

class MainVC: NSViewController {
    
    @IBOutlet weak var backgroundView: NSView!
    @IBOutlet weak var statusImageView: NSImageView!
    @IBOutlet weak var statusLabel: NSTextFieldCell!
    @IBOutlet weak var taskLabel: NSTextField!
    @IBOutlet weak var dragView: DragView!
    
    private var destFolder: String!
    private var currentOutput: String!

    /// 拖进来的文件（夹）
    lazy var dragFileList: [FileItem] = [FileItem]()
    /// 遍历出的所有文件
    lazy var allFileList: NSMutableArray = []
    /// car文件CARExtractor解压程序路径
    var carExtractorLocation: String!
    /// 支持处理的类型，目前仅支持png、jpg、ipa、car文件
    var extensionList: [String]!
    /// 在拖新文件进来时是否需要清空现在列表
    var needClearDragList: Bool!
    /// 文件保存文件夹
    var destFolderPath: String? {
        set {
            self.destFolder = newValue
        }
        get {
            if self.destFolder == nil {
                let date = DateFormatter()
                date.dateFormat = "yyyy-MM-dd"
                let d = date.string(from: Date.init())
                let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.downloadsDirectory,
                                                               FileManager.SearchPathDomainMask.userDomainMask,
                                                               true).first
                self.destFolder = (path! as NSString).appendingPathComponent("图标提取/" + d)
                if !FileManager.default.fileExists(atPath: self.destFolder! as String) {
                    MainVC.createDirectory(withPath: self.destFolder!)
                }
            }
            return self.destFolder
        }
    }
    /// 当前输出路径
    var currentOutputPath: String? {
        set {
            self.currentOutput = newValue
        }
        get {
            if currentOutput == nil {
                let date = DateFormatter()
                date.dateFormat = "HH-mm-ss"
                let d = date.string(from: Date.init())
                self.currentOutput = (self.destFolderPath! as NSString).appendingPathComponent(d)
                MainVC.createDirectory(withPath: self.currentOutput!)
            }
            return self.currentOutput
        }
    }
    
    var gifView: GifView!
    
    /// 退出程序
    @IBAction func closeWindow(_ sender: AnyObject) {
        exit(0)
    }
    
    /// 最小化
    @IBAction func miniaturizeWindow(_ sender: AnyObject) {
        self.view.window?.miniaturize(self)
    }
    
    /// 最大化
    @IBAction func zoomWindow(_ sender: AnyObject) {
        self.view.window?.zoom(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dragView.delegate = self
        
        var tmpPath = Bundle.main.resourcePath! + "/CARExtractor"
        if !(FileManager.default.fileExists(atPath: tmpPath)) {
            tmpPath = ""
        }
        self.carExtractorLocation = tmpPath
        self.needClearDragList = true
        self.extensionList = ["ipa","car","png","jpg"]
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor.white.cgColor
        
        gifView = GifView(frame: NSRect(x: 0, y: 0, width: 185, height: 185))
        gifView.setImage(withImage: NSImage.init(named: "itsnottoolate.gif")!)
        self.dragView.addSubview(gifView)
        gifView.isHidden = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(MainVC.setTaskString(notification:)),
                                               name: NSNotification.Name(rawValue: "updataForStatusLabel"),
                                               object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UI更新相关
extension MainVC {
    
    func setTaskString(notification: NSNotification) {
        let dict = notification.userInfo!
        let title = dict["title"]
        taskLabel.stringValue = title as! String
    }
    
    func setStatusString(stauts: String) {
        DispatchQueue.main.async {
            self.statusLabel.stringValue = stauts
        }
    }
}

// MARK: - 文件拖拽代理
extension MainVC: DragViewDelegate {
    
    /// 处理拖拽文件代理
    func dragView(dragView: DragView, didDragItems items: [String]) {
        self.addPaths(withItems: items)
        self.gifView.isHidden = false
    }
    /// 添加拖拽进来的文件
    func addPaths(withItems items: [String]) {
        
        //  如果清空文件列表，清空后重置参数
        if self.needClearDragList == true {
            self.allFileList.removeAllObjects()
            self.needClearDragList = false
        }
        
        for addItem in items {
            
            let fileItem = FileItem.fileItem(withPath: addItem)
            
            //print(fileItem.isDirectory, fileItem.isFileExists, fileItem.filePath, fileItem.fileName)
            
            //  如果不是文件夹
            if !(fileItem.isDirectory.boolValue) {
                //  获取文件类型
                var isExpectExtension = false
                let pathExtension = (addItem as NSString).pathExtension
                
                //  如果支持该类型，跳出
                for item in extensionList {
                    if item == pathExtension {
                        isExpectExtension = true
                        break
                    }
                }
                //  如果不支持该类型，继续
                if !isExpectExtension {
                    continue
                }
            }
            //  如果路径已经存在，跳出
            var isExist = false
            for dataItem in dragFileList {
                if dataItem.filePath == addItem {
                    isExist = true
                    break
                }
            }
            //  如果路径不存在，添加到文件列表
            if !isExist {
                self.dragFileList.append(fileItem)
            }
        }
        startTask()
    }
}

// MARK: - 任务相关操作
extension MainVC {
    
    func startTask() {
        
        taskLabel.stringValue = "正在处理"
        
        if dragFileList.count < 1 {
            let alert = NSAlert()
            alert.messageText = "错误原因"
            alert.informativeText = "没有文件拖拽到窗口或不支持拖入的文件类型"
            alert.addButton(withTitle: "好的")
            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            self.cleanTask()
            return
        }
        
        self.dragView.dragEnable = false
        self.currentOutputPath = nil
        
        DispatchQueue.global().async {
            
            self.getAllFilesFromDragPaths()
            
            //  处理已有的png和jpg文件
            let imgPredicate = NSPredicate(format: "SELF.filePath.pathExtension IN {'jpg', 'png'}")
            let imagesArray = self.allFileList.filtered(using: imgPredicate)
            
            if imagesArray.count > 0 {
                let existImagesPath = (self.currentOutputPath! as NSString).appendingPathComponent("ImagesOutput")
                MainVC.createDirectory(withPath: existImagesPath)
                for item in imagesArray {
                    let path = (item as! FileItem).filePath as NSString
                    self.doPngOrJpgFile(withPath: path, outputPath: existImagesPath)
                    self.setStatusString(stauts: "图片文件：\((item as! FileItem).fileName)")
                }
            }
            
            //  处理car文件
            let carPredicate = NSPredicate(format: "SELF.filePath.pathExtension == 'car'")
            let carArray = self.allFileList.filtered(using: carPredicate)
            if carArray.count > 0 {
                let existCarPath = (self.currentOutputPath! as NSString).appendingPathComponent("CarFilesOutput")
                MainVC.createDirectory(withPath: existCarPath)
                for item in carArray {
                    let outputPath = existCarPath + "/car_images_" + MainVC.getRandomString(withCount: 5)
                    let filePath = (item as! FileItem).filePath
                    self.doCarFiles(withPath: filePath, outputPath: outputPath)
                    self.setStatusString(stauts: "Car文件：\((item as! FileItem).fileName)")
                }
            }
            
            //  处理ipa文件
            self.doIpaFile()
            
            DispatchQueue.main.async {
                self.setStatusString(stauts: "完成")
                self.dragView.dragEnable = true
                //  重置参数
                self.needClearDragList = true
                self.allFileList.removeAllObjects()
                self.openFolder()
            }
        }
    }
    
    func openFolder() {
        
        if currentOutputPath != nil {
            let fileURLs = NSArray(objects: NSURL.init(fileURLWithPath: currentOutputPath!))
            NSWorkspace.shared().activateFileViewerSelecting(fileURLs as! [URL])
        }
        else {
            let alert = NSAlert()
            alert.messageText = "错误原因"
            alert.informativeText = "输出文件夹未创建或已删除，请重新拖拽文件"
            alert.addButton(withTitle: "好的")
            alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            cleanTask()
        }
        
        cleanTask()
    }
    
    func cleanTask() {
        
        DispatchQueue.main.async {
            self.dragFileList.removeAll()
            self.currentOutputPath = nil
            self.setStatusString(stauts: "支持iPA、Car、JPG、PNG文件类型和文件夹")
            self.taskLabel.stringValue = "拖拽文件到这里"
            self.gifView.isHidden = true
        }
        
    }
}


// MARK: - 文件操作
extension MainVC {
    
    /// 遍历获取拖进来的所有的文件
    func getAllFilesFromDragPaths() {
        
        self.allFileList.removeAllObjects()
        for fileItem in dragFileList {
            //  如果是文件夹
            if fileItem.isDirectory.boolValue {
                //  获取文件夹下所有文件
                let list = MainVC.getFileList(withPath: fileItem.filePath, extensions: extensionList)
                self.allFileList.addObjects(from: list)
            }
            else {
                self.allFileList.add(fileItem)
            }
        }
    }
    
    /// 处理ipa文件
    func doIpaFile() {
        
        let predicate = NSPredicate(format: "SELF.filePath.pathExtension == 'ipa'")
        let ipaArray = self.allFileList.filtered(using: predicate) as! [FileItem]
        
        for item in ipaArray {
            
            self.setStatusString(stauts: "iPa文件：\(item.fileName)")
            
            let folderName = item.fileName.replacingOccurrences(of: ".", with: "_")
            var outputPath = (self.currentOutputPath! as NSString).appendingPathComponent(folderName)
            let unzipPath = (outputPath as NSString).appendingPathComponent("tmp")
            
            do {
                try SSZipArchive.unzipFile(atPath: item.filePath,
                                           toDestination: unzipPath,
                                           overwrite: true,
                                           password: nil)
                
                self.doZipFiles(withPath: unzipPath, outputPath: &outputPath)
            }
            catch {
                print("解压出错")
            }
            do {
                try FileManager.default.removeItem(atPath: unzipPath)
            }
            catch {
                print("删除临时文件出错")
            }
        }
    }
    
    /// 处理解压的文件
    ///
    /// - parameter path:       输出路径
    /// - parameter outputPath: 输出路径
    func doZipFiles(withPath path: String, outputPath: inout String) {
        
        let zipFileList = MainVC.getFileList(withPath: path, extensions: ["png", "jpg", "car"])
        
        for fileItem in zipFileList {
            
            let pathExtension = (fileItem.filePath as NSString).pathExtension
            var carArray = [FileItem]()
            
            if pathExtension == "car" {
                carArray.append(fileItem)
            }
            else {
                //  处理png和jpg文件
                self.setStatusString(stauts: "图片文件：\(fileItem.fileName)")
                self.doPngOrJpgFile(withPath: (fileItem.filePath as NSString), outputPath: outputPath)
            }
            
            for item in carArray {
                self.setStatusString(stauts: "Car文件：\(fileItem.fileName)")
                let outPath = (outputPath as NSString).appendingPathComponent("car_images")
                self.doCarFiles(withPath: item.filePath, outputPath: outPath)
            }
        }
    }
    
    /// 处理png或者jpg文件
    ///
    /// - parameter path:       文件路径
    /// - parameter outputPath: 保存路径
    func doPngOrJpgFile(withPath path: NSString, outputPath: String) {
        
        let tmpImage = NSImage(contentsOfFile: path as String)
        
        if tmpImage == nil {
            return
        }
        
        let fileType = path.pathExtension
        var saveData: Data? = nil
        
        if fileType == "png" {
            saveData = self.imageData(withImage: tmpImage!, bitmapImageFileType: NSPNGFileType)
        }
        else if fileType == "jpg" {
            saveData = self.imageData(withImage: tmpImage!, bitmapImageFileType: NSJPEGFileType)
        }
        
        if (saveData != nil) {
            let savePath = (outputPath as NSString).appendingPathComponent(path.lastPathComponent)
            (saveData! as NSData).write(toFile: savePath, atomically: true)
        }
    }
    
    /// 将NSImage对象转换成png,jpg...NSData
    func imageData(withImage image: NSImage, bitmapImageFileType fileType: NSBitmapImageFileType) -> Data? {
        
        if let d = image.tiffRepresentation {
            let rep: NSBitmapImageRep = NSBitmapImageRep(data: d)!
            return rep.representation(using: fileType, properties: [:])
        }
        else {
            print("image 为空值")
            return nil
        }
    }
    
    /// 用CARExtractor程序处理Assets.car文件
    ///
    /// - parameter path:       Assets.car路径
    /// - parameter outputPath: 保存路径
    func doCarFiles(withPath path: String, outputPath: String) {

        if self.carExtractorLocation == "" {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "错误原因"
                alert.informativeText = "没有找到 CARExtractor / 程序损坏，请重新安装."
                alert.addButton(withTitle: "好的")
                alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
                self.cleanTask()
            }
            return
        }
        
        let task = Process()
        task.launchPath = self.carExtractorLocation
        task.arguments = ["-i", path, "-o", outputPath]
        let pipe = Pipe()
        task.standardOutput = pipe
        pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable,
                                               object: pipe.fileHandleForReading,
                                               queue: nil){ (notification) in
                                                pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
        
        task.launch()
        task.waitUntilExit()
        
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.NSFileHandleDataAvailable,
                                                  object: pipe.fileHandleForReading)
    }
}

// MARK: - 文件夹操作
extension MainVC {
    
    /// 遍历路径下特定扩展名的文件
    ///
    /// - parameter withPath:   遍历路径
    /// - parameter extensions: 包含的扩展名
    ///
    /// - returns: 特定扩展名的文件目录
    class func getFileList(withPath path: String, extensions: [String]) -> [FileItem] {
        
        var retArray = [FileItem]()
        
        do {
            //  获取路径下所有文件（夹）名称
            let contentsOfFolder = try FileManager.default.contentsOfDirectory(atPath: path)
            for aPath in contentsOfFolder {
                //  创建文件（夹）完整路径
                let fullPath = (path as NSString).appendingPathComponent(aPath)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir) {
                    //  如果是文件夹
                    if isDir.boolValue == true {
                        //  继续获取文件
                        let tmpArr = MainVC.getFileList(withPath: fullPath, extensions: extensions)
                        //  将文件列表插入目录
                        //retArray.insert(contentsOf: tmpArr, at: 0)
                        retArray.append(contentsOf: tmpArr)
                    }
                    else {
                        //  获取文件类型
                        var isExpectExtension = false
                        let pathExtension = (fullPath as NSString).pathExtension
                        for fileType in extensions {
                            if fileType == pathExtension {
                                isExpectExtension = true
                                break
                            }
                        }
                        if isExpectExtension {
                            retArray.append(FileItem.fileItem(withPath: fullPath))
                        }
                    }
                }
            }
        }
        catch {
            print(error)
        }
        return retArray
    }
    
    /// 创建文件夹路径
    ///
    /// - parameter path: 目录路径
    class func createDirectory(withPath path: String) {
        if FileManager.default.fileExists(atPath: path, isDirectory: nil) {
            return
        }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("创建文件夹失败")
        }
    }
    
    /// 获取随机字符串
    class func getRandomString(withCount count: NSInteger) -> String {
        
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        var str = ""
        for _ in 0...count {
            let index = Int(arc4random_uniform(UInt32(characters.characters.count)))
            let i = characters.index(characters.startIndex, offsetBy: index)
            str.append(characters[i])
        }
        return str
    }
    
}



