//
//  AppDelegate.swift
//  RxUIApplicationDelegate
//
//  Created by brian.semiglia@gmail.com on 09/12/2018.
//  Copyright (c) 2018 brian.semiglia@gmail.com. All rights reserved.
//

import UIKit
import RxSwift
import RxUIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  let backing = RxUIApplicationDelegate(
    initial: .empty
  )
  let cleanup = DisposeBag()
  
  override init() {
    backing.render(
      new: .empty,
      old: .empty
    )
    backing
      .output
      .subscribe { _ in }
      .disposed(
        by: cleanup
      )
  }
  
  override open func forwardingTarget(for input: Selector!) -> Any? { return
    backing
  }
  
  override open func responds(to input: Selector!) -> Bool { return
    backing
      .responds(
        to: input
      )
  }

}

