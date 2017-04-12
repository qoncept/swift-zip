import Foundation
import Cminizip


public func unzip(data: Data) -> [String: Data] {
    var data = data

    let bufferSize = 4096
    
    var filefunc32 = zlib_filefunc_def()
    var unzmem = ourmemory_t()
    
    unzmem.size = uLong(bufferSize)
    data.withUnsafeMutableBytes {
        unzmem.base = $0
    }
    
    fill_memory_filefunc(&filefunc32, &unzmem);
    
    let file = unzOpen2("____", &filefunc32)
    
    guard unzGoToFirstFile(file) == UNZ_OK else {
        fatalError()
    }
    
    var ret: [String: Data] = [:]
    
    readloop: while true {
        var fileInfo = unz_file_info()
        var filename = [CChar](repeating: 0, count: Int(PATH_MAX))
        unzGetCurrentFileInfo(file, &fileInfo, &filename, uLong(PATH_MAX), nil, 0, nil, 0)
        
        unzOpenCurrentFile(file)
        var out = Data()
        var buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate(capacity: bufferSize) }
        while true {
            let len = unzReadCurrentFile(file, buffer, UInt32(bufferSize))
            if len > 0 {
                // read
                out.append(buffer, count: Int(len))
            } else if len == 0 {
                // end
                break
            } else {
                fatalError()
            }
        }
        unzCloseCurrentFile(file)
        
        ret[String(cString: filename)] = out
        
        switch unzGoToNextFile(file) {
        case UNZ_END_OF_LIST_OF_FILE:
            break readloop
        default:
            break
        }
    }
    unzClose(file)
    
    return ret
}

enum SwiftZipError: Error {
    
}
