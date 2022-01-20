//
//  ColorActivity.swift
//  HSharePlay
//
//  Created by huangqun on 2021/11/2.
//

import Foundation
import GroupActivities

struct ColorActivity: GroupActivity {
    
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "同播共享--换颜色"
        // 设置活动类型为通用
        metadata.type = .generic
        return metadata
    }
}
