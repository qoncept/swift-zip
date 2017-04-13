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
    
    let file = unzOpen2("__nouse__", &filefunc32)
    
    guard unzGoToFirstFile(file) == UNZ_OK else {
        fatalError("Failed `unzGoToFirstFile`")
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
            guard len >= 0 else {
                fatalError("Failed to read file.")
            }
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

public func zip(entries: [String: Data]) -> Data {
    
    var filefunc32 = zlib_filefunc_def();
    var zipmem = ourmemory_t();
    defer { zipmem.base.deallocate(capacity: Int(zipmem.size)) }
    
    zipmem.grow = 1;
    
    fill_memory_filefunc(&filefunc32, &zipmem);
    guard let file = zipOpen3("", APPEND_STATUS_CREATE, 0, nil, &filefunc32) else {
        fatalError("Failed to open.")
    }
    
    for (filename, filedata) in entries {
        var zipinfo = zip_fileinfo()
        zipOpenNewFileInZip3(file, filename, &zipinfo, nil, 0, nil, 0, nil, Z_DEFLATED, Z_DEFAULT_COMPRESSION, 0, -MAX_WBITS, DEF_MEM_LEVEL, Z_DEFAULT_STRATEGY, nil, 0)
        let result = filedata.withUnsafeBytes {
            zipWriteInFileInZip(file, $0, UInt32(filedata.count))
        }
        guard result == ZIP_OK else {
            fatalError("Failed to write file.")
        }
        zipCloseFileInZip(file)
    }
    zipClose(file, nil)
    
    let data = Data(bytes: zipmem.base, count: Int(zipmem.limit))
    
    return data
}
