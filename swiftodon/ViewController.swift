//
//  ViewController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/21.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let con = AccountListViewController(nibName: nil, bundle: nil)
        let nav = UINavigationController(rootViewController: con)
        present(nav, animated: true, completion: nil)
        
    }

    @IBAction func open(sender: Any) {
        let controller = AddAccountViewController()
        let nav = UINavigationController(rootViewController: controller)
        self.present(nav, animated: true, completion: nil)
    }
}

