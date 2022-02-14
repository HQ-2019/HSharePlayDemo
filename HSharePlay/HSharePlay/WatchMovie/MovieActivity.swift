//
//  MovieActivity.swift
//  HSharePlay
//
//  Created by huangqun on 2021/11/8.
//

import Foundation
import GroupActivities

struct MovieActivity: GroupActivity {
    
    let movie: Movie
    
    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        // 设置活动类型为一起观看影片
        metadata.type = .watchTogether
        metadata.title = "这里为影片名称"
        // 影片的网络地址
        metadata.fallbackURL = movie.url
        return metadata
    }
}



/// 用于传输播放影片的信息
struct Movie: Hashable, Codable {
    /// 视  频地址类型
    enum UrlType: Hashable, Codable {
        /// 本地视频
        case local
        /// 远程视频
        case remote
    }
    
    /// 影片地址
    var url: URL
    
    /// 影片标题
    var title: String
    
    /// 影片开始播放的时间
    var startTime: TimeInterval
    
    /// 视频地址类型
    var urlTpye: UrlType
}
