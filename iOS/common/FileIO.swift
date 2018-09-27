
import Foundation


class FileIO {
    
    
    private let fileManager = FileManager.default
    private var path: URL?
    
    
    init(_ name: String, directory: String? = nil) {
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard var document = urls.first else {
            print("openDocument Fail")
            return
        }
        
        if let directory = directory {
            document = openDirectory(directory, topPath: document)
        }
        
        path = document.appendingPathComponent(name)
    }
    
    
    private func openFile(_ name: String, topPath: URL) -> URL {
        let filePath = topPath.appendingPathComponent(name)
        
        if !isExist(filePath.path) {
            if !fileManager.createFile(atPath: filePath.path, contents: nil, attributes: nil) {
                print("createFile Fail")
                return topPath
            }
        }
        
        return filePath
    }
    
    
    private func openDirectory(_ name: String, topPath: URL) -> URL {
        let directoryPath = topPath.appendingPathComponent(name, isDirectory: true)
        
        if !isExist(directoryPath.path, isDirectory: true) {
            do {
                try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: true, attributes:nil)
            } catch {
                print("createDirectory Fail")
                return topPath
            }
        }
        
        return directoryPath
    }
    
    
    func isExist() -> Bool {
        guard let path = path else { return false }
        return isExist(path.path)
    }
    
    
    private func isExist(_ path: String, isDirectory: Bool = false) -> Bool {
        var ret = false
        
        if isDirectory {
            var objcBool = ObjCBool(true)
            let exists = fileManager.fileExists(atPath: path, isDirectory: &objcBool)
            ret = exists && objcBool.boolValue
        } else {
            ret = fileManager.fileExists(atPath: path)
        }
        
        return ret
    }
    
    
    func remove() {
        guard let path = path else { return }
        do {
            try fileManager.removeItem(at: path)
        } catch {
            print("error remove file")
        }
    }
    
    
    func clear() {
        guard let path = path else { return }
        do {
            try "".write(to: path, atomically: true, encoding: .utf8)
        } catch {
            print("clear Fail")
        }
    }
    
    
    func write(_ text: String) -> Bool {
        guard let path = path else { return false }
        do {
            try text.write(to: path, atomically: false, encoding: .utf8)
            return true
        } catch {
            print("writeText Fail")
        }
        return false
    }
    
    
    func read() -> String? {
        guard let path = path else { return nil }
        do {
            return try String(contentsOf: path, encoding: .utf8)
        } catch {
            print("readText Fail")
        }
        return nil
    }
}
