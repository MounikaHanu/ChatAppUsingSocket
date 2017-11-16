//
//  UsersViewController.swift
//  SocketChat
//
//  Created by Gabriel Theodoropoulos on 1/31/16.
//  Copyright © 2016 AppCoda. All rights reserved.
//

import UIKit

class UsersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tblUserList: UITableView!
    
    
    var users = [[String: AnyObject]]()
    
    var nickname: String! = "name"
    
    var configurationOK = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !configurationOK {
            configureNavigationBar()
            configureTableView()
            configurationOK = true
        }
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if nickname == nil {
            askForNickname()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    


    // MARK: - Navigation
 
    // In a storyboard-based application, you will often want to do a little preparation before navigation
     func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier {
            if identifier == "idSegueJoinChat" {
                let chatViewController = segue.destination as! ChatViewController
                chatViewController.nickname = nickname
                print(chatViewController.nickname)
            }
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "idSegueJoinChat", sender: nil)
    }

    
    // MARK: IBAction Methods
    
   
    @IBAction func exitChat(_ sender: UIBarButtonItem) {
        
        SocketIOManager.sharedInstance.exitChatWithNickName(nickName: nickname) {
            DispatchQueue.main.async {
                self.nickname = nil
                self.users.removeAll()
                self.tblUserList.isHidden = true
                self.askForNickname()
            }
        }
    }
    
    //Display Users
    func askForNickname() {
       /* let alertcontroller = UIAlertController(title: "socketChat", message: "please enter a name", preferredStyle: .alert)
        alertcontroller.addTextField(configurationHandler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) -> Void in
            let textField = alertcontroller.textFields![0]
            if textField.text?.count == 0 {
                self.askForNickname()
            }else {
               self.nickname = textField.text
                print(self.nickname)*/
                
                SocketIOManager.sharedInstance.connectToServerWithNickName(nickname: "name", completionHandler: { (userlist)-> Void in
                    DispatchQueue.main.async {
                        if userlist != nil {
                            self.users = userlist!
                            self.tblUserList.reloadData()
                            self.tblUserList.isHidden = false
                        } else {
                            print("no users found")
                        }
                    }
                })
            //}
            
        //}
        
        //alertcontroller.addAction(okAction)
        //present(alertcontroller, animated: true, completion: nil)
    }
    
    
    // MARK: Custom Methods
    
    func configureNavigationBar() {
        navigationItem.title = "SocketChat"
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    
    func configureTableView() {
        tblUserList.delegate = self
        tblUserList.dataSource = self
        tblUserList.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "idCellUser")
        tblUserList.isHidden = true
        tblUserList.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    
    // MARK: UITableView Delegate and Datasource methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "idCellUser", for: indexPath as IndexPath) as! UserCell
        cell.textLabel?.text = users[indexPath.row]["nickname"] as? String
        cell.detailTextLabel?.text = (users[indexPath.row]["isconnected"] as! Bool) ? "Online" : "Offline"
        cell.detailTextLabel?.textColor = (users[indexPath.row]["isConnected"] as! Bool) ? UIColor.clear : UIColor.darkGray
        
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
}
