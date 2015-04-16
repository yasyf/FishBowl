//
//  Logger.swift
//  FishBowl
//
//  Created by Yasyf Mohamedali on 2015-04-16.
//  Copyright (c) 2015 com.fishbowl. All rights reserved.
//

import Foundation
import Crashlytics

func CLS_LOG_SWIFT( _ format: String = "", _ args:[CVarArgType] = [], file: String = __FILE__, function: String = __FUNCTION__, line: Int = __LINE__)
{
    #if DEBUG
        CLSNSLogv("\(file.lastPathComponent.stringByDeletingPathExtension).\(function) line \(line) $ \(format)", getVaList(args))
    #else
        CLSLogv("\(file.lastPathComponent.stringByDeletingPathExtension).\(function) line \(line) $ \(format)", getVaList(args))
    #endif
    
}