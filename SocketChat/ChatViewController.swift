//
//  ChatViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tblChat: UITableView!
    
    @IBOutlet weak var lblOtherUserActivityStatus: UILabel!
    
    @IBOutlet weak var tvMessageEditor: UITextView!
    
    @IBOutlet weak var conBottomEditor: NSLayoutConstraint!
    
    @IBOutlet weak var lblNewsBanner: UILabel!
    
    
    
    var nickname: String! = "name"
    
    var chatMessages = [[String: AnyObject]]()
    
    var bannerLabelTimer: Timer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //NotificationCenter.default.addObserver(self, selector: "handleKeyboardDidShowNotification", name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        //NotificationCenter.default.addObserver(self, selector: "handleKeyboardDidHideNotification", name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: "handleConnectedUserUpdateNotification" , name: NSNotification.Name(rawValue: "userWasConnectedNotification:"), object: nil)
        NotificationCenter.default.addObserver(self, selector: "handleDisconnectedUserUpdateNotification:", name: NSNotification.Name(rawValue: "userWasDisconnectedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: "handleUserTypingNotification", name: NSNotification.Name(rawValue: "userTypingNotification"), object: nil)
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.down
        swipeGestureRecognizer.delegate = self
        view.addGestureRecognizer(swipeGestureRecognizer)
//        SocketIOManager.sharedInstance.connectToServerWithNickName(nickname: nickname) { (dict) in
//            print(dict)
//        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
        configureNewsBannerLabel()
        configureOtherUserActivityLabel()
        
        tvMessageEditor.delegate = self
    }
    
    // for receiving new messages.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SocketIOManager.sharedInstance.getChatMessage { (messageInfo) in
            DispatchQueue.main.async {
                self.chatMessages.append(messageInfo)
                self.tblChat.reloadData()
            }
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: IBAction Methods
    
    @IBAction func sendMessage(_ sender: UIButton) {
        if tvMessageEditor.text.count > 0 {
            SocketIOManager.sharedInstance.sendMessage(message: tvMessageEditor.text!, withNickName: nickname)
      
            tvMessageEditor.resignFirstResponder()
            
            var message = [String: AnyObject]()
            //message = tvMessageEditor.text
            chatMessages.append(message)
            tvMessageEditor.text = ""
            tblChat.reloadData()
            
        }
    }
    
    

    
    // MARK: Custom Methods
    
    func configureTableView() {
        tblChat.delegate = self
        tblChat.dataSource = self
        tblChat.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "idCellChat")
        tblChat.estimatedRowHeight = 90.0
        tblChat.rowHeight = UITableViewAutomaticDimension
        tblChat.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func handleUserTypingNotification(notification: NSNotification){
        if let typingUsersDictionary = notification.object as? [String: AnyObject]{
            var names = ""
            var totalTypingUsers = 0
            for(typingUser, _) in typingUsersDictionary {
                if typingUser != nickname{
                    names = (names == "") ? typingUser: "\(names),\(typingUser)"
                    totalTypingUsers += 1
                }
            }
            if totalTypingUsers > 0 {
                let verb = (totalTypingUsers == 1) ? "is" : "are"
                lblOtherUserActivityStatus.text = "\(names) \(verb) now typing a message"
                lblOtherUserActivityStatus.isHidden = false
                
            } else {
              lblOtherUserActivityStatus.isHidden = true
            }
        }
        
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        SocketIOManager.sharedInstance.sendStartTypingMessage(nickname: nickname)
        return true
    }
    
//    func dismissKeyboard() {
//        if tvMessageEditor.isFirstResponder() {
//            tvMessageEditor.resignFirstResponder()
//            SocketIOManager.sharedInstance.sendStopTypingMessage(nickname: nickname)
//            
//        }
//    }
    
    func configureNewsBannerLabel() {
        lblNewsBanner.layer.cornerRadius = 15.0
        lblNewsBanner.clipsToBounds = true
        lblNewsBanner.alpha = 0.0
    }
    
    
    func configureOtherUserActivityLabel() {
        lblOtherUserActivityStatus.isHidden = true
        lblOtherUserActivityStatus.text = ""
    }
    
    
    func handleKeyboardDidShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                conBottomEditor.constant = keyboardFrame.size.height
                view.layoutIfNeeded()
            }
        }
    }
    
    
    func handleKeyboardDidHideNotification(notification: NSNotification) {
        conBottomEditor.constant = 0
        view.layoutIfNeeded()
    }
    
    
    func scrollToBottom(closure:()-> Void) {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.chatMessages.count > 0 {
                let lastRowIndexPath = NSIndexPath(row: self.chatMessages.count - 1, section: 0)
                self.tblChat.scrollToRow(at: lastRowIndexPath as IndexPath, at: UITableViewScrollPosition.bottom, animated: true)
            }
        }
//        dispatch_after(dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), { () -> Void in
//            if self.chatMessages.count > 0 {
//                let lastRowIndexPath = NSIndexPath(forRow: self.chatMessages.count - 1, inSection: 0)
//                self.tblChat.scrollToRow(at: lastRowIndexPath as IndexPath, at: UITableViewScrollPosition.bottom, animated: true)
//            }
//        }),dispatch_get_main_queue, closure)
//
    }
    
    func handleConnectedUserUpdateNotification(notification: NSNotification){
        let connectedUserInfo = notification.object as? [String: AnyObject]
        let connectedUserNickName = connectedUserInfo!["nickname"] as? String
        lblNewsBanner.text = "User \(connectedUserNickName!.uppercased()) was just connected"
        showBannerLabelAnimated()
    }
    
    
    func showBannerLabelAnimated() {
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 1.0
            
            }) { (finished) -> Void in
                self.bannerLabelTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: "hideBannerLabel", userInfo: nil, repeats: false)
        }
    }
    
    func handleDisconnectedUserUpdateNotification(notification: NSNotification) {
        let disconnectedUserNickName = notification.object as? String
        lblNewsBanner.text = "User \(disconnectedUserNickName?.uppercased()) has left"
        showBannerLabelAnimated()
    }
    
    func hideBannerLabel() {
        if bannerLabelTimer != nil {
            bannerLabelTimer.invalidate()
            bannerLabelTimer = nil
        }
        
        UIView.animate(withDuration: 0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 0.0
            
            }) { (finished) -> Void in
        }
    }

    
    
    func dismissKeyboard() {
        if tvMessageEditor.isFirstResponder {
            tvMessageEditor.resignFirstResponder()
            SocketIOManager.sharedInstance.sendStopTypingMessage(nickname: nickname)
        }
    }
    
    
    
    // MARK: UITableView Delegate and Datasource Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellChat", for: indexPath as IndexPath) as! ChatCell
        let currentChatMessage = chatMessages[indexPath.row]
        let senderNickName = currentChatMessage["nickname"] as? String
        let message = currentChatMessage["message"] as? String
        let messageDate = currentChatMessage["date"] as? String
        if senderNickName == nickname {
            cell.lblChatMessage.textAlignment = NSTextAlignment.right
            cell.lblChatMessage.textAlignment = NSTextAlignment.left
            cell.lblChatMessage.textColor = lblNewsBanner.backgroundColor
        }
        cell.lblChatMessage.text = message
        cell.lblMessageDetails.text = "by \(senderNickName?.uppercased()) @ \(messageDate))"
        cell.lblChatMessage.textColor = UIColor.darkGray
        
        return cell
    }
    
    
    // MARK: UITextViewDelegate Methods
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        return true
    }

    
    // MARK: UIGestureRecognizerDelegate Methods
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
