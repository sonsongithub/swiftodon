//
//  AccountListViewController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/26.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit

class AccountListViewController: UITableViewController {
    var list: [MastodonSession] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AccountListViewController.load(notification:)), name: MastodonSessionUpdateNotification, object: nil)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(AccountListViewController.add(sender:)))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(AccountListViewController.cancel(sender:)))
        
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        load()
    }
    
    func cancel(sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func add(sender: Any) {
        let alert:UIAlertController = UIAlertController(title:"Add new host", message: "", preferredStyle: .alert)
        do {
            let action = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            }
            alert.addAction(action)
        }
        do {
            let action = UIAlertAction(title: "Add", style: .default) { (action) in
                if let text = alert.textFields?[0].text {
                    do {
                        try MastodonSession.delete(host: text)
                    } catch {
                        print(error)
                    }
                    
                    MastodonSession.add(host: text)
                }
            }
            alert.addAction(action)
        }
        alert.addTextField { (textField) in
            textField.placeholder = "example: mastodon.social"
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    func load(notification: NSNotification) {
        list = MastodonSession.sessions()
        tableView.reloadData()
    }

    func load() {
        list = MastodonSession.sessions()
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return list.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let session = list[indexPath.row]
        cell.textLabel?.text = "\(session.userName)@\(session.host)"

        return cell
    }
 
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let session = list[indexPath.row]
            do {
                try MastodonSession.delete(session: session)
                list.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                print(error)
            }
        }
    }
}
