//
//  Logger.swift
//
//  Created by Luke Davis on 11/24/18.
//  Copyright © 2018 Luke Davis. All rights reserved.
//

import Foundation

class Log {
    // 1. The date formatter
    private static var dateFormat = "hh:mm:ssSSS" // Use your own
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        return formatter
    }
    
    private static func sourceFileName(filePath: String) -> String {
        let components = filePath.components(separatedBy: "/")
        return components.isEmpty ? "" : components.last!
    }
    
    private static func toString(date: Date) -> String {
        return Log.dateFormatter.string(from: date)
    }
    
    /// ERROR log
    ///
    /// - Parameters:
    ///   - object: The data to be displayed
    ///   - filename: The filename in which log occured
    ///   - line: The line on which the log occured
    ///   - column: The column in which the log occured
    ///   - funcName: The name of the function in which the log occurred
    public static func e( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        let date = Date()
        
        print("\(toString(date: date)) \(LogEvent.e.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
    }
    
    /// DEBUG log
    ///
    /// - Parameters:
    ///   - object: The data to be displayed
    ///   - filename: The filename in which log occured
    ///   - line: The line on which the log occured
    ///   - column: The column in which the log occured
    ///   - funcName: The name of the function in which the log occurred
    public static func d( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        let date = Date()
        
        print("\(toString(date: date)) \(LogEvent.d.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
    }
    
    /// INFO log
    ///
    /// - Parameters:
    ///   - object: The data to be displayed
    ///   - filename: The filename in which log occured
    ///   - line: The line on which the log occured
    ///   - column: The column in which the log occured
    ///   - funcName: The name of the function in which the log occurred
    public static func i( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        let date = Date()
        
        print("\(toString(date: date)) \(LogEvent.i.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
    }
    
    /// VERBOSE log
    ///
    /// - Parameters:
    ///   - object: The data to be displayed
    ///   - filename: The filename in which log occured
    ///   - line: The line on which the log occured
    ///   - column: The column in which the log occured
    ///   - funcName: The name of the function in which the log occurred
    public static func v( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        let date = Date()
        
        print("\(toString(date: date)) \(LogEvent.v.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
    }
    
    /// WARNING log
    ///
    /// - Parameters:
    ///   - object: The data to be displayed
    ///   - filename: The filename in which log occured
    ///   - line: The line on which the log occured
    ///   - column: The column in which the log occured
    ///   - funcName: The name of the function in which the log occurred
    public static func w( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        let date = Date()
        
        print("\(toString(date: date)) \(LogEvent.w.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
    }
    
    /// SEVERE log
    ///
    /// - Parameters:
    ///   - object: The data to be displayed
    ///   - filename: The filename in which log occured
    ///   - line: The line on which the log occured
    ///   - column: The column in which the log occured
    ///   - funcName: The name of the function in which the log occurred
    public static func s( _ object: Any, filename: String = #file, line: Int = #line, column: Int = #column, funcName: String = #function) {
        let date = Date()
        
        print("\(toString(date: date)) \(LogEvent.s.rawValue)[\(sourceFileName(filePath: filename))]:\(line) \(column) \(funcName) -> \(object)")
    }
}

enum LogEvent: String {
    case e = "[‼️]" // error
    case i = "[ℹ️]" // info
    case d = "[💬]" // debug
    case v = "[🔬]" // verbose
    case w = "[⚠️]" // warning
    case s = "[🔥]" // severe
}

