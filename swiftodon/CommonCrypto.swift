//
//  CommonCrypto.swift
//  2tch
//
//  Created by sonson on 2017/03/10.
//  Copyright © 2017年 sonson. All rights reserved.
//

import Foundation
import CommonCrypto

/**
 MD5のdigest計算メソッドのラッパー
 - parameter p1: digestを計算したいデータのバイト列．
 - parameter length: digestを計算したいデータのサイズ．単位はバイト．
 - parameter md: 計算したdigestが保存されるポインタ．ハッシュ値以上のサイズが必要．
 */
func _CC_MD5(p1: UnsafeRawPointer!, length: CC_LONG, md: UnsafeMutablePointer<UInt8>) {
    CC_MD5(p1, length, md)
}

/**
 SHA1のdigest計算メソッドのラッパー
 - parameter p1: digestを計算したいデータのバイト列．
 - parameter length: digestを計算したいデータのサイズ．単位はバイト．
 - parameter md: 計算したdigestが保存されるポインタ．ハッシュ値以上のサイズが必要．
 */
func _CC_SHA1(p1: UnsafeRawPointer!, length: CC_LONG, md: UnsafeMutablePointer<UInt8>) {
    CC_SHA1(p1, length, md)
}

/**
 SHA256のdigest計算メソッドのラッパー
 - parameter p1: digestを計算したいデータのバイト列．
 - parameter length: digestを計算したいデータのサイズ．単位はバイト．
 - parameter md: 計算したdigestが保存されるポインタ．ハッシュ値以上のサイズが必要．
 */
func _CC_SHA256(p1: UnsafeRawPointer!, length: CC_LONG, md: UnsafeMutablePointer<UInt8>) {
    CC_SHA256(p1, length, md)
}

/**
 SHA384のdigest計算メソッドのラッパー
 - parameter p1: digestを計算したいデータのバイト列．
 - parameter length: digestを計算したいデータのサイズ．単位はバイト．
 - parameter md: 計算したdigestが保存されるポインタ．ハッシュ値以上のサイズが必要．
 */
func _CC_SHA384(p1: UnsafeRawPointer!, length: CC_LONG, md: UnsafeMutablePointer<UInt8>) {
    CC_SHA384(p1, length, md)
}

/**
 SHA512のdigest計算メソッドのラッパー
 - parameter p1: digestを計算したいデータのバイト列．
 - parameter length: digestを計算したいデータのサイズ．単位はバイト．
 - parameter md: 計算したdigestが保存されるポインタ．ハッシュ値以上のサイズが必要．
 */
func _CC_SHA512(p1: UnsafeRawPointer!, length: CC_LONG, md: UnsafeMutablePointer<UInt8>) {
    CC_SHA512(p1, length, md)
}

/**
 SHA224のdigest計算メソッドのラッパー
 - parameter p1: digestを計算したいデータのバイト列．
 - parameter length: digestを計算したいデータのサイズ．単位はバイト．
 - parameter md: 計算したdigestが保存されるポインタ．ハッシュ値以上のサイズが必要．
 */
func _CC_SHA224(p1: UnsafeRawPointer!, length: CC_LONG, md: UnsafeMutablePointer<UInt8>) {
    CC_SHA224(p1, length, md)
}

// MARK: - CommonCrypto

/**
 digest, HMACの計算アルゴリズムのタイプ．
 全部は面倒臭いので実装していない．
 */
public enum HashType {
    case sha1
    case md5
    case sha256
    case sha384
    case sha512
    case sha224
    
    /// HMACの計算アルゴリズムを指定するときに使う識別子．
    var algorithm: UInt32 {
        switch self {
        case .sha1:
            return CCHmacAlgorithm(kCCHmacAlgSHA1)
        case .md5:
            return CCHmacAlgorithm(kCCHmacAlgMD5)
        case .sha256:
            return CCHmacAlgorithm(kCCHmacAlgSHA256)
        case .sha384:
            return CCHmacAlgorithm(kCCHmacAlgSHA384)
        case .sha512:
            return CCHmacAlgorithm(kCCHmacAlgSHA512)
        case .sha224:
            return CCHmacAlgorithm(kCCHmacAlgSHA224)
        }
    }
    
    /// 各アルゴリズムのdigestのバイト長．
    var digestLength: Int {
        switch self {
        case .sha1:
            return Int(CC_SHA1_DIGEST_LENGTH)
        case .md5:
            return Int(CC_MD5_DIGEST_LENGTH)
        case .sha256:
            return Int(CC_SHA256_DIGEST_LENGTH)
        case .sha384:
            return Int(CC_SHA384_DIGEST_LENGTH)
        case .sha512:
            return Int(CC_SHA512_DIGEST_LENGTH)
        case .sha224:
            return Int(CC_SHA224_DIGEST_LENGTH)
        }
    }
    
    /// 各アルゴリズムのdigestを計算するメソッド．
    /// 関数型を返す．
    var digest: (UnsafeRawPointer, CC_LONG, UnsafeMutablePointer<UInt8>) -> Void {
        switch self {
        case .sha1:
            return _CC_SHA1
        case .md5:
            return _CC_MD5
        case .sha256:
            return _CC_SHA256
        case .sha384:
            return _CC_SHA384
        case .sha512:
            return _CC_SHA512
        case .sha224:
            return _CC_SHA224
        }
    }
}

/**
 UInt8のポインタから，"b0823"という文字列を生成する．
 - parameter body: To be written.
 - parameter length: To be written.
 - returns: To be written.
 */
fileprivate func _hex(body: UnsafePointer<UInt8>, length: Int) -> String {
    var result = ""
    for i in 0..<length {
        result = result.appendingFormat("%02x", body[i])
    }
    return result
}

extension Data {
    
    /**
     指定されたアルゴリズムで計算したdigestのデータを返す．
     - parameter type: To be written.
     - returns: To be written.
     */
    public func digest(type: HashType) -> Data {
        var destinationBuffer = [UInt8](repeating: 0, count: type.digestLength)
        return self.withUnsafeBytes({ (body: UnsafePointer<UInt8>) -> Data in
            let p = UnsafeRawPointer(body)
            type.digest(p, UInt32(self.count), &destinationBuffer)
            return Data(bytes: destinationBuffer)
        })
    }
    
    /**
     指定されたアルゴリズムで計算したdigestを文字列で返す．
     - parameter type: To be written.
     - returns: To be written.
     */
    public func digest(type: HashType) -> String {
        let data: Data = self.digest(type: type)
        return data.hex
    }
    
    /**
     データから，"b0823"というような16進数の文字列を生成する．
     - returns: To be written.
     */
    fileprivate var hex: String {
        return self.withUnsafeBytes { return _hex(body: $0, length: self.count) }
    }
    
}

extension String {
    
    /**
     文字列から文字列のバイト長と，文字列をデコードした生のデータを[UInt8]型で返す．
     - returns: バイト長と，文字列をデコードした生のデータ．
     */
    fileprivate func decode() -> (Int, [UInt8]) {
        let length = (self as NSString).lengthOfBytes(using: String.Encoding.utf8.rawValue)
        var buffer = [UInt8](repeating: 0, count: length)
        (self as NSString).getBytes(&buffer, maxLength: length, usedLength: nil, encoding: String.Encoding.utf8.rawValue, options: [], range: NSRange(location: 0, length: self.utf16.count), remaining: nil)
        return (length, buffer)
    }
    
    /**
     指定されたアルゴリズムで計算したdigestをデータ型で返す．
     - parameter type: digestを計算するアルゴリズム．
     - returns: digestのデータ．
     */
    public func digest(type: HashType) -> Data {
        let (length, buffer) = decode()
        
        var digestBuffer = [UInt8](repeating: 0, count: type.digestLength)
        type.digest(buffer, UInt32(length), &digestBuffer)
        return Data(bytes: digestBuffer)
    }
    
    /**
     指定されたアルゴリズムで計算したdigestを文字列で返す．
     - parameter type: digestを計算するアルゴリズム．
     - returns: digestの文字列．
     */
    public func digest(type: HashType) -> String {
        let data: Data = self.digest(type: type)
        return data.hex
    }
    
    /**
     鍵付きのハッシュ値(HMAC: Keyed-Hashing for Message Authentication)を返す．
     - parameter key: 鍵．文字列で指定する．
     - parameter type: ハッシュ値（digest）を計算するアルゴリズム．
     - returns: digestのデータ．
     */
    public func hmac(with key: String, type: HashType) -> Data {
        
        let (length, buffer) = decode()
        let (keyLength, keyBuffer) = key.decode()
        
        var digestBuffer = [UInt8](repeating: 0, count: type.digestLength)
        
        var hmacContext = CCHmacContext()
        CCHmacInit(&hmacContext, type.algorithm, keyBuffer, keyLength)
        CCHmacUpdate(&hmacContext, buffer, length)
        CCHmacFinal(&hmacContext, &digestBuffer)
        
        return Data(bytes: digestBuffer)
    }
    
    /**
     鍵付きのハッシュ値(HMAC: Keyed-Hashing for Message Authentication)を返す．
     - parameter key: 鍵．文字列で指定する．
     - parameter type: ハッシュ値（digest）を計算するアルゴリズム．
     - returns: digestの文字列．
     */
    public func hmac(with key: String, type: HashType) -> String {
        return hmac(with: key, type: type).hex
    }
}
