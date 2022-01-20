//
//  MovieView.swift
//  HSharePlay
//
//  Created by huangqun on 2021/11/8.
//

import SwiftUI
import GroupActivities
import Combine
import AVKit

struct MovieView: View {
    
    @State var groupSession: GroupSession<MovieActivity>?
    @State var subscriptions = Set<AnyCancellable>()
    
    /// 电影列表数据
    let movieList = [
        Movie(url: Bundle.main.url(forResource: "video", withExtension: "mp4")!,
              title: "本地视频",
              startTime: 0,
              urlTpye: .local),
        Movie(url: URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2020/10653/8/E739CC44-25A9-46B9-8E40-1788530C5785/master.m3u8")!,
              title: "远程视频",
              startTime: 0,
              urlTpye: .remote)
    ]
    
    /// 播放器
    @State var player: AVPlayer = AVPlayer()
    

    var body: some View {
        VStack {
            // 播放视频失败
            VideoPlayer(player: player)
                .frame(height: 200)
            
            HStack {
                Button {
                    let rewindDuration = CMTime(value: 5, timescale: 1)
                    let rewindTime = self.player.currentTime() - rewindDuration
                    self.player.seek(to: rewindTime)
                    self.player.play()
                } label: {
                    Text("同步快退")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .frame(width: 70, height: 30)
                .background(Color.red)
                .cornerRadius(4)
                
                Button {
                    let speedDuration = CMTime(value: 5, timescale: 1)
                    let speedTime = self.player.currentTime() + speedDuration
                    self.player.seek(to: speedTime)
                    self.player.play()
                } label: {
                    Text("同步快进")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                }
                .frame(width: 70, height: 30)
                .background(Color.green)
                .cornerRadius(4)
                
                Spacer().frame(width: 20)
                
//                Button {
//                    let suspension = self.player.playbackCoordinator.beginSuspension(for: .whatHappened)
//                    self.player.pause()
//                } label: {
//                    Text("暂停自己")
//                        .font(.system(size: 12))
//                        .foregroundColor(.white)
//                }
//                .frame(width: 70, height: 30)
//                .background(Color.red)
//                .cornerRadius(4)
//
//                Button {
//                    let suspension = self.player.playbackCoordinator.beginSuspension(for: .whatHappened)
//                    self.player.play()
//                    suspension.end()
//                } label: {
//                    Text("恢复暂停")
//                        .font(.system(size: 12))
//                        .foregroundColor(.white)
//                }
//                .frame(width: 70, height: 30)
//                .background(Color.green)
//                .cornerRadius(4)
            }

            Spacer().frame(height: 50)
            
            Button {
                self.prepareToPlay(self.movieList[0])
            } label: {
                Text("切换本地视频").foregroundColor(.white)
            }
            .frame(width: 120, height: 40)
            .background(Color.red)
            .cornerRadius(4)
            
            Button {
                self.prepareToPlay(self.movieList[1])
            } label: {
                Text("切换远程视频").foregroundColor(.white)
            }
            .frame(width: 120, height: 40)
            .background(Color.red)
            .cornerRadius(4)
            
            Spacer()
        }
        .task {
            for await session in MovieActivity.sessions() {
                self.configureGroupSession(session)
            }
        }
    }
    
    /// 配置同播共享的会话信息
    func configureGroupSession(_ session: GroupSession<MovieActivity>) {
        self.groupSession = session
        self.player.playbackCoordinator.coordinateWithSession(session)
        
        // 监听会话状态
        session.$state
            .sink { state in
                print("会话状态变更")
                if case .invalidated = state {
                    // 重置会话
                    self.groupSession = nil
                    self.subscriptions.removeAll()
                }
            }
            .store(in: &subscriptions)
        
        // 监听活动
        session.$activity
            .sink { activity in
                print( "当前活动变更  " + activity.metadata.title!)
                self.handleMoiveMessage(activity.movie)
            }
            .store(in: &subscriptions)

        
        // 加入会话（当前设备启动共享）
        session.join()
    }
    
    
    /// 装备播放视频（询问是否进行同播共享）
    func prepareToPlay(_ playMovie: Movie) {
        // 提示是否授权开启同播共享
        let activity = MovieActivity(movie: playMovie)
        Task {
            switch await activity.prepareForActivation() {
            case .activationDisabled:
                self.player.replaceCurrentItem(with: AVPlayerItem(url: playMovie.url))
                print("11111111111")
                break
            case .activationPreferred:
                // 当 FaceTime 通话处于活动状态时，立即开始活动并为应用程序创建会话。
                _ = try await activity.activate()
                print("222222222222")
                break
            case .cancelled:
                print("333333333333")
                break
            @unknown default:
                print("44444444444")
                break
            }
        }
    }
    
    /// 接收处理会话中传来的消息
    func handleMoiveMessage(_ message: Movie) {
        let url = self.movieList[message.urlTpye == .local ?  0 : 1].url
        self.player.replaceCurrentItem(with: AVPlayerItem(url: url))
    }
}

struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        MovieView()
    }
}

/// 这种方式创建的播放的多一个全屏的按钮显示
//struct Player: UIViewControllerRepresentable {
//
//    func makeUIViewController(context: Context) -> some UIViewController {
//        let controller = AVPlayerViewController()
//        let url = Bundle.main.url(forResource: "video", withExtension: "mp4")
//        let player = AVPlayer(url: url!)
//        controller.player = player
//        return controller
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
//    }
//}


//extension AVCoordinatedPlaybackSuspension.Reason {
//    static var whatHappened = AVCoordinatedPlaybackSuspension.Reason(rawValue: "groupwatching.suspension.what-happened")
//}
