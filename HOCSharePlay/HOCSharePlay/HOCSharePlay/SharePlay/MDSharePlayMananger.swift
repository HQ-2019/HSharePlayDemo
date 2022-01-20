//
//  CoordinationManager.swift
//  MDMotionOrientation
//
//  Created by huangqun on 2021/11/11.
//

import Foundation
import GroupActivities
import Combine

@available(iOS 15, *)
@objc public class MDSharePlayMananger: NSObject {

    @objc public static let shared = MDSharePlayMananger()

    var groupSession: GroupSession<MDGenericGroupActivity>?
    var sessionMessenger: GroupSessionMessenger?
    var subscriptions = Set<AnyCancellable>()
    var tasks = Set<Task<Void, Never>>()
    
    // 通过block回调消息事件（目前暂时不需要）
    public typealias MessageCallBack = (_ message:String) -> Void
    @objc public var messageCallBack: MessageCallBack?
    
    /// 当前设备用户发出的消息（目前用来匹对远程的消息是否是当前设备用户自己触发的）
    private var messageModel: MDOCMessageModel?
    
    /// 开启活动会话检索（尽量在程序启动时调用，避免从同播共享链接启动应用时，应用无法正确响应活动信息的问题）
    @objc public func startSession() {
        Task {
            for await session in MDGenericGroupActivity.sessions() {
                // FaceTime在通话中并且程序调用activity.activate()后才会收到回调
                self.configureGroupSession(session)
            }
        }
    }
    
    /// 准备同播共享
    /// 如果未加入活动会话，则开启同播共享活动会话
    /// 如果已加入活动会话，根据newActivity判断是切换活动还是当成消息发送
    @objc public func prepareToPlay(_ message: MDOCMessageModel) {
        
        if self.isJoinedActivity() {
            
            // 活动会话内只有自己时，重新开启活动会话
            if self.groupSession!.activeParticipants.count < 2 {
                self.startSharing(message)
                return
            }
            
            // 切换活动
            if message.type == .sendActivity {
                self.changeSharingInfo(message)
                return
            }
            
            // 活动内发送消息
            self.sendMessage(message)
            return
        }
        
        // 开启活动
        self.startSharing(message)
    }
    
    ///  开启活动会话
    ///  执行try await activity.activate()后for await session in MDGenericGroupActivity.sessions() {}才会有回调信息
    /// - Parameters:
    @objc public func startSharing(_ message: MDOCMessageModel) {
        Task {
            let model = MDActivityMessageModel(uuid: message.uuid, url: message.url, title: message.title)
            let activity = MDGenericGroupActivity(model: model)
            
            // 询问是否将内容分享到会话队列中（如何询问会有弹窗提示）
            switch await activity.prepareForActivation() {
            case .activationDisabled:
                break
            case .activationPreferred:
                do {
                    self.messageModel = message
                    _ = try await activity.activate()
                } catch {
                    print("无法激活活动: \(error)")
                }
            case .cancelled:
                break
            default:
                break;
            }
            
            // 不询问 直接分享活动到会话队列中
//            do {
//                _ = try await activity.activate()
//            } catch {
//                print("Unable to activate the activity: \(error)")
//            }
        }
    }
    
    /// 切换分享活动（内容也会改变，如果活动会话组里只有自己的话也不会重新发送活动激活）
    /// 会在session.$activity.sink{}中接收到活动数据
    /// - Parameters:
    @objc public func changeSharingInfo(_ message: MDOCMessageModel) {
        self.messageModel = message
        let model = MDActivityMessageModel(uuid: message.uuid, url: message.url, title: message.title)
        self.groupSession?.activity = MDGenericGroupActivity(model: model)
    }
    
    /// 发送分享内容（在同一个活动下发送新数据），
    /// 会在for await (message, _) in messenger.messages(of: PathModel.self) {} 中接收到数据
    /// - Parameters:
    @objc public func sendMessage(_ message: MDOCMessageModel) {
        if let messenger = self.sessionMessenger {
            Task {
                self.messageModel = message
                let model = MDActivityMessageModel(uuid: message.uuid, url: message.url, title: message.title)
                try? await messenger.send(model)
            }
        }
    }
    
    /// 配置同播共享的会话信息
    private func configureGroupSession(_ session: GroupSession<MDGenericGroupActivity>) {
        self.groupSession = session
        let messenger = GroupSessionMessenger(session: session)
        self.sessionMessenger = messenger
        // 监听会话状态
        session.$state
            .sink { state in
                print("会话状态变更 state: \(state)")
                if case .invalidated = state {
                    // 重置会话
                    self.groupSession = nil
                    self.sessionMessenger = nil
                    self.tasks.removeAll()
                    self.subscriptions.removeAll()
                }
            }
            .store(in: &subscriptions)

        // 监听活动
        session.$activity
            .sink { activity in
                print( "当前活动变更")
                self.handleMessage(activity.model)
            }
            .store(in: &subscriptions)

        // 监听活动参与者
        session.$activeParticipants
            .sink { activeParticipants in
                print("当前活动的参与者数两: \(session.activeParticipants)")
                let newParticipants = activeParticipants.subtracting(session.activeParticipants)
//                    .filter { participant in
//                        // 将自己过滤
//                        participant.id != self.groupSession?.localParticipant.id
//                    }
                print("将当前的数据同步给新的参与者: \(newParticipants.count)" + "  数据: \(String(describing: self.groupSession?.activity.model))")
                Task {
                    try? await messenger.send(self.groupSession?.activity.model, to:.only(newParticipants))
                }
            }
            .store(in: &subscriptions)

        // 接收来自其他设备的信息（通过messenger.send发送的数据）
        let task = Task {
            for await (message, _) in messenger.messages(of: MDActivityMessageModel.self) {
                print("接收到远程推送的新消息")
                handleMessage(message)
            }
        }
        self.tasks.insert(task)

        // 加入活动会话
        session.join()
    }

    /// 接收处理会话中传来的消息
    private func handleMessage(_ message: MDActivityMessageModel) {
        print("处理远程过来的消息: \(String(describing: message))")
        // 如果是用户自己发出的消息，不处理
        if !message.uuid.uuidString.isEqual(self.messageModel?.uuid.uuidString)  {
            SystemManager.jump(toViewWihtUrl: message.url, controller: nil)
        }
    }
    
    /// 当前设备是否已经加入活动会话
    /// - Returns: true为未加入
    @objc public func isJoinedActivity() -> Bool {
        return  self.groupSession != nil && self.sessionMessenger != nil && self.groupSession?.state == .joined
    }
    
    /// 离开当前活动，并停止接收消息（仅自己，活动组内其他成员还在）
    @objc public func leaveActivity() {
        self.groupSession?.leave()
    }
    
    /// 结束整个活动组（组内所有人都离开活动会话）
    @objc public func endActivity() {
        self.groupSession?.end()
    }
}
