//
//  PlayColorView.swift
//  HSharePlay
//
//  Created by huangqun on 2021/11/2.
//

import SwiftUI
import GroupActivities
import Combine

struct PlayColorView: View {
    
    @ObservedObject var color = PlayColor()
    
    @State var groupSession: GroupSession<ColorActivity>?
    @State var sessionMessenger: GroupSessionMessenger?
    @State var subscriptions = Set<AnyCancellable>()
    @State var tasks = Set<Task<Void, Never>>()
    
    var body: some View {
        VStack {
            
            Button {
                self.color.updateColor()
                
                // 当内容改变时发送给会话中的其他设备
                if let messenger = sessionMessenger {
                    Task {
                        try? await messenger.send(self.color.colorRgb)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .foregroundColor(Color(red: color.colorRgb.colorB, green: color.colorRgb.colorG, blue: color.colorRgb.colorB))
                        .frame(width: 200, height: 200)
                        .overlay {
                            Capsule()
                                .stroke(lineWidth: 5)
                                .padding(30)
                                .foregroundColor(.white)
                        }
                    Text(self.color.colorRgb.text)
                        .foregroundColor(.white)
                }
            }
            
            Spacer().frame(height: 50)
            
            Text("开始玩同播共享")
                .padding()
                .background(Color.purple)
                .cornerRadius(6)
                .onTapGesture {
                    self.startPlayTapped()
                }
            
            Spacer().frame(height: 20)
            
            Text("重置")
                .padding()
                .background(Color.purple)
                .cornerRadius(6)
                .onTapGesture {
                    self.reset()
                }
        }
        .task {
            for await session in ColorActivity.sessions() {
                self.configureGroupSession(session)
            }
        }
    }
    
    func startPlayTapped() {
        let activity = ColorActivity()
        
        // 提示是否授权开启同播共享
        Task {
            switch await activity.prepareForActivation() {
            case .activationDisabled:
                break
            case .activationPreferred:
                // 当 FaceTime 通话处于活动状态时，立即开始活动并为应用程序创建会话。
                _ = try await activity.activate()
                break
            case .cancelled:
                break
            @unknown default:
                break
            }
        }
    }
    
    /// 重置
    func reset() {
        self.groupSession = nil
        self.sessionMessenger = nil
        self.tasks.removeAll()
        self.subscriptions.removeAll()
        self.color.colorRgb = MessageColor(colorR: 1.0, colorG: 0, colorB: 0, text: "点击换色")
    }
    
    /// 配置同播共享的会话信息
    func configureGroupSession(_ session: GroupSession<ColorActivity>) {
        self.groupSession = session
        let messenger = GroupSessionMessenger(session: session)
        self.sessionMessenger = messenger
        // 监听会话状态
        session.$state
            .sink { state in
                print("会话状态变更 state: \(state)")
                if case .invalidated = state {
                    // 重置会话
                    self.reset()
                }
            }
            .store(in: &subscriptions)
        
        // 监听活动
        session.$activity
            .sink { activity in
                print( "当前活动变更:  " + activity.metadata.title!)
            }
            .store(in: &subscriptions)
        
        // 监听活动参与者
        session.$activeParticipants
            .sink { activeParticipants in
                print("会话参与者变更  当前参与者数目 \(session.activeParticipants)")
                let newParticipants = activeParticipants.subtracting(session.activeParticipants)
                
                // 将当前的数据发送给新的参与者
                Task {
                    print("将当前的数据同步给新的参与者 \(newParticipants.count)")
                    try? await messenger.send(self.color.colorRgb, to:.only(newParticipants))
                }
                
            }
            .store(in: &subscriptions)
        
        // 接收来自其他设备的信息
        let task = Task {
            for await (message, _) in messenger.messages(of: MessageColor.self) {
                handleMessage(message)
            }
        }
        self.tasks.insert(task)
        
        // 加入会话（当前设备启动共享）
        session.join()

    }
    
    /// 接收处理会话中传来的消息
    func handleMessage(_ message: MessageColor) {
        self.color.colorRgb = message
        print("接收到数据变更")
    }
}

class PlayColor: ObservableObject {

    @Published var colorRgb: MessageColor
    
    init(colorRgb: MessageColor = MessageColor(colorR: 1.0, colorG: 0.0, colorB: 0.0, text: "点击换色")) {
        self.colorRgb = colorRgb
    }
    
    /// 更新颜色(随机)
    func updateColor() {
        let red = CGFloat(arc4random() % 256) / 255.0
        let green = CGFloat(arc4random() % 256) / 255.0
        let blue = CGFloat(arc4random() % 256) / 255.0
        let text = "点击换色" + "\nr:" +  red.description + "\ng:" +  green.description  + "\nb:" +  blue.description
        self.colorRgb = MessageColor(colorR: red, colorG: green, colorB: blue, text: text)
    }
}

struct PlayColorView_Previews: PreviewProvider {
    static var previews: some View {
        PlayColorView()
    }
}
