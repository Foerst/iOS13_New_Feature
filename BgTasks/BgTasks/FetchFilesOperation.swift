//
//  SplashScreenOpration.swift
//  BgTasks
//
//  Created by CXY on 2020/4/2.
//  Copyright © 2020 jc. All rights reserved.
//

import UIKit

class FetchFilesOperation: Operation {
    
    private var urlString: String?
    
    private lazy var cache = URLCache(memoryCapacity: 0, diskCapacity: 100 * 1024 * 1024, diskPath: "SplashScreenCache")
    
    private var _isExecuting = false
    
    private var _isFinished = false
    
    init(url: String) {
        super.init()
        self.urlString = url
    }
    
    override var isExecuting: Bool {
        return _isExecuting
    }
    
    override var isFinished: Bool {
        return _isFinished
    }
    
    // isAsynchronous表示手动调用start方法时，操作是同步还是异步。添加到OperatonQueue时忽略此属性
    override var isAsynchronous: Bool {
        return true
    }
    
    // A Boolean value indicating whether the operation executes its task asynchronously.
    override var isConcurrent: Bool {
        return true
    }
    
    override func start() {
        // Always check for cancellation before launching the task.
        if isCancelled {
            willChangeValue(forKey: "isFinished")
            _isFinished = true
            didChangeValue(forKey: "isFinished")
            return
        }
        
        // If the operation is not canceled, begin executing the task.
        willChangeValue(forKey: "isExecuting")
        Thread.detachNewThreadSelector(#selector(main), toTarget: self, with: nil)
        _isExecuting = true
        didChangeValue(forKey: "isExecuting")
    }

    override func main() {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            completeOperation()
            return
        }

        print("Thread = \(Thread.current)")
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.requestCachePolicy = .returnCacheDataElseLoad
        sessionConfiguration.urlCache = cache
        let session = URLSession(configuration: sessionConfiguration)
        let dataTask = session.dataTask(with: url) {[weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            if error == nil {
                let cachedData = CachedURLResponse(response: response!, data: data!)
                let urlRequest = URLRequest(url: url)
                strongSelf.cache.storeCachedResponse(cachedData, for: urlRequest)
            }
            strongSelf.completeOperation()
        }
        dataTask.resume()
    }
    
    
    private func completeOperation() {
        willChangeValue(forKey: "isFinished")
        willChangeValue(forKey: "isExecuting")
        _isExecuting = false
        _isFinished = true
        didChangeValue(forKey: "isFinished")
        didChangeValue(forKey: "isExecuting")
        
        print("cachePath = \(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)")
    }

    deinit {
        print("SplashScreenOpration \(Thread.current) 释放")
    }

}
