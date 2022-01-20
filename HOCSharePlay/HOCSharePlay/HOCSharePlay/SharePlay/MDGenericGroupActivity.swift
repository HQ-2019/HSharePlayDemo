//
//  MDGenericGroupActivity.swift
//  MDMotionOrientation
//
//  Created by huangqun on 2021/11/11.
//

import Foundation
import GroupActivities

@available(iOS 15, *)
struct MDGenericGroupActivity: GroupActivity {
    
    let model: MDActivityMessageModel
    
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = model.title
        // 设置活动类型为通用
        metadata.type = .generic
        return metadata
    }
}

/// 同播共享活动会话使用的消息模型，必须可编解码
struct MDActivityMessageModel: Codable {
    
    var uuid: UUID
    
    /// 分享的页面路径
    var url: String
    
    /// 分享的内容名称
    var title: String
}

/// 为OC调用swift提供的消息模型
@objc public class MDOCMessageModel: NSObject {
    
    @objc public var uuid = UUID()
    
    /// 分享的页面路径
    @objc public var url: String = ""
    
    /// 分享的内容名称
    @objc public var title: String = ""
    
    /// 分享活动类型： true为活动  false为发送消息
    @objc public var type: MDOCActivityType = MDOCActivityType.sendActivity
}

/// 活动数据类型
@objc public enum MDOCActivityType: Int, Codable {
    
    /// 发送消息
    case sendMessage
    
    /// 发送活动
    case sendActivity
}
