//
//  MessageColor.swift
//  HSharePlay
//
//  Created by huangqun on 2021/11/5.
//

import Foundation
import SwiftUI

/// 用于发送的消失提，其中的所有属性必须支持编解码协议
struct MessageColor: Codable {
    // Color不支持 Decodable 协议，使用RGB值来替代
    let colorR: CGFloat
    let colorG: CGFloat
    let colorB: CGFloat
    
    let text: String
}



