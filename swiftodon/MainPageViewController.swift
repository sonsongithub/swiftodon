//
//  MainPageViewController.swift
//  swiftodon
//
//  Created by sonson on 2017/04/28.
//  Copyright © 2017年 sonson. All rights reserved.
//

import UIKit
import swiftodon

protocol Page {
    var index: Int { get set }
}

class MainPageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    var sessions: [MastodonSession] = []
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewControllerOptionInterPageSpacingKey: 20])
        self.dataSource = self
        self.delegate = self
        
//        do {
//            sessions = try MastodonSession.sessions()
//            let controller = TimelineViewController(
//            let nav = UINavigationController(rootViewController: controller)
//        } catch {
//            print(error)
//        }
//        contents = []
//        
//        let controller = ThreadTabViewController()
//        let nav = UINavigationController(rootViewController: controller)
//        
//        controller.content = contents[0]
//        controller.index = 0
//        setViewControllers([nav], direction: .forward, animated: false, completion: nil)
        
        self.view.backgroundColor = .lightGray
    }
    
    required init?(coder: NSCoder) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewControllerOptionInterPageSpacingKey: 20])
        self.dataSource = self
        self.delegate = self
        self.view.backgroundColor = .lightGray
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(MainPageViewController.load(notification:)), name: MastodonSessionUpdateNotification, object: nil)

//        MastodonSessionUpdateNotification
        // Do any additional setup after loading the view.
    }
    
    func load(notification: NSNotification) {
        do {
            sessions = try MastodonSession.sessions()
//            if list.count > 0 {
//                home = TimelineController(session: list[0], type: .home)
//                local = TimelineController(session: list[0], type: .local)
//                union = TimelineController(session: list[0], type: .union)
//                home?.textViewWidth = self.view.frame.size.width - 16
//                try home?.update()
//            }
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UIPageViewController
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        /// callback
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
//        guard let nav = viewController as? UINavigationController else { return nil }
//        guard let viewController = nav.visibleViewController else { return nil }
//        if let viewController = viewController as? Page {
//            let index = viewController.index + 1
//            
//            if contents.count <= index {
//                return nil
//            }
//            
//            let controller = ThreadTabViewController()
//            controller.content = contents[index]
//            controller.index = index
//            let nav = UINavigationController(rootViewController: controller)
//            return nav
//        }
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
//        guard let nav = viewController as? UINavigationController else { return nil }
//        guard let viewController = nav.visibleViewController else { return nil }
//        if let viewController = viewController as? Page {
//            let index = viewController.index - 1
//            if index < 0 {
//                return nil
//            }
//            let controller = ThreadTabViewController()
//            controller.content = contents[index]
//            controller.index = index
//            let nav = UINavigationController(rootViewController: controller)
//            return nav
//        }
        return nil
    }
}
