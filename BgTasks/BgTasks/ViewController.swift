//
//  ViewController.swift
//  BgTasks
//
//  Created by CXY on 2020/4/2.
//  Copyright © 2020 jc. All rights reserved.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    private lazy var queue = OperationQueue()

    override func viewDidLoad() {
        super.viewDidLoad()
//        let op = FetchFilesOperation(url: fileUrl)
//        OperationQueue().addOperation(op)
////        op.start()
//
//
//        let op2 = BlockOperation {
//
//        }
//        op2.start()
//
//        let op3 = MyOperation()
//        op3.start()
//
//        print("\(op.isAsynchronous)")
//        print("\(op2.isAsynchronous)")
//        print("\(op3.isAsynchronous)")
        
        
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: sessionConfiguration)
        let url = URL(string: fileUrl)!
        let dataTask = session.dataTask(with: url) {[weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
        }
        dataTask.resume()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkCacheAndPlay()
    }
    
    private func checkCacheAndPlay() {
        let cache = URLCache(memoryCapacity: 0, diskCapacity: 100 * 1024 * 1024, diskPath: "SplashScreenCache")
        let url = URL(string: fileUrl)!
        let urlRequest = URLRequest(url: url)
        
        if let response = cache.cachedResponse(for: urlRequest) {
            let localUrl = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!).appendingPathComponent("file.mp4")
            do {
                try response.data.write(to: localUrl)
            } catch {
                print(error.localizedDescription)
            }
            
            let player = AVPlayer(playerItem: AVPlayerItem(url: localUrl))
            let vc = AVPlayerViewController()
            vc.player = player
            present(vc, animated: true) {
                player.play()
            }
        } else {
            let op = FetchFilesOperation(url: fileUrl)
            queue.addOperation(op)
        }
    }


}

