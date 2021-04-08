//
//  FileMonitor.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import SPCCore

class FileMonitor {
    
    private var fileSystemObject : DispatchSourceFileSystemObject?
    
    init?(url: URL, eventMask: DispatchSource.FileSystemEvent, eventHandler: @escaping (() -> Void)) {

        let fileDescriptor : CInt = open(url.path, O_EVTONLY)
        if fileDescriptor < 0  {
            PBLog("Could not open file descriptor.")
            return nil
        }
        
        fileSystemObject = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: eventMask, queue: .global())

        guard let fileSystemObject = self.fileSystemObject else {
            close(fileDescriptor)
            PBLog("Could not create DispatchSource.")
            return nil
        }
        
        fileSystemObject.setEventHandler {
            eventHandler()
        }
        
        fileSystemObject.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileSystemObject.resume()
    }
    
    deinit { 
        fileSystemObject?.cancel()
        fileSystemObject = nil
    }
    
    func start() {
        fileSystemObject?.resume()
    }
    
    func stop() {
        fileSystemObject?.suspend()
    }
}
