//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Mounika Nerella on 11/14/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import UIKit
import SocketIO

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    
    var socket: SocketIOClient = SocketIOClient(socketURL:URL(string:"http://192.168.1.20:3000")!)
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
    
    
    // Here we are connecting the user to server with nickname and giving a completion block with entering the userslist as array of dictionaries.
    func connectToServerWithNickName(nickname: String,completionHandler: @escaping (_ userList:[[String: AnyObject]]?) ->Void) {
        //send an event to server with optional data items.
        socket.emit("connectUser",nickname)
        print(socket.status)
        print(socket.emit("connectUser", nickname))
        //listen to socket for any message regarding the userlist and grab it when using completion handler when it comes back from server.
        socket.on("userList") { (dataArray, ack) -> Void in
            completionHandler(dataArray[0] as! [[String: AnyObject]])
            self.listenForOtherMessages()
        }
    }
        func exitChatWithNickName(nickName: String,completionHandler: ()-> Void) {
            socket.emit("exitUser", nickName)
            completionHandler()
        }
    
//    Chat Process Starts
    
    func sendMessage(message: String,withNickName givenickName: String){
        
        socket.emit("chatMessage",givenickName,message)
        
    }
    
    private func listenForOtherMessages() {
        socket.on("userConnectedUpdate") { (dataArray, socketAck) in
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasConnectedNotification"), object: dataArray[0] as? [String: AnyObject])
            self.socket.on("userTypingUpdate", callback: { (dataArray, socketAck) in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userTypingNotification"), object: dataArray[0] as? String)
            })
            self.socket.on("userExitUpdate", callback: { (dataArray, socketAck) in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: dataArray[0] as? [String: AnyObject])
            })
        }
    }
    
    func getChatMessage(completionHandler: @escaping (_ messageInfo: [String: AnyObject])-> Void) {
        
        socket.on("newChatMessage") { (dataArray, socketAck) in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["nickname"] = dataArray[0] as! String as AnyObject
            messageDictionary["message"] = dataArray[1] as? String as AnyObject
            messageDictionary["date"] = dataArray[2] as? String as AnyObject
            completionHandler(messageDictionary)
        }
    }
    func sendStartTypingMessage(nickname: String) {
        socket.emit("startType", nickname)
    }
    
    func sendStopTypingMessage(nickname: String) {
        socket.emit("stopType", nickname)
    }
    
}
