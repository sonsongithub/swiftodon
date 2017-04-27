//
//  ViewController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/27.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit
import swiftodon

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewController.add(sender:)))
    }
    
    func add(sender: Any) {
        let con = AccountListViewController(nibName: nil, bundle: nil)
        let nav = UINavigationController(rootViewController: con)
        present(nav, animated: true, completion: nil)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

