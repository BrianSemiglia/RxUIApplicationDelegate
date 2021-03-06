//
//  RxUIApplicationTestCase.swift
//  Cycle
//
//  Created by Brian Semiglia on 1/27/17.
//  Copyright © 2017 Brian Semiglia. All rights reserved.
//

import XCTest
import RxUIApplicationDelegate
import RxSwift

class RxUIApplicationTestCase: XCTestCase {
  
  // Starts with EMPTY always
  static func statesFromCall(
    initial: RxUIApplicationDelegate.Model = .empty,
    call: (UIApplicationDelegate) -> Any
  ) -> [RxUIApplicationDelegate.Model] {
    var output: [RxUIApplicationDelegate.Model] = []
    let application = RxUIApplicationDelegate(initial: initial)
    _ = application
      .eventsCapturedAfterRendering(.just(initial))
      .subscribe(onNext: { new in
        output += [new]
      })
    _ = call(application as UIApplicationDelegate)
    return output
  }
  
  // Only starts with EMPTY if not specified, thus difference with -statesFromCall
  static func statesFrom(
    stream: Observable<RxUIApplicationDelegate.Model>,
    model: RxUIApplicationDelegate.Model = .empty
  ) -> [RxUIApplicationDelegate.Model] {
    var output: [RxUIApplicationDelegate.Model] = []
    let application = RxUIApplicationDelegate(initial: model)
    _ = application
      .eventsCapturedAfterRendering(stream)
      .subscribe(onNext: { new in
        output += [new]
      })
    return output
  }
  
  func testWillTerminate() {
    
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationWillTerminate!(UIApplication.shared) }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .pre(.terminated)]
    )
  }

  func testDidBecomeActive() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationDidBecomeActive!(UIApplication.shared) }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .currently(.active(.some))]
    )
  }
  
  func testWillResignActive() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationWillResignActive!(UIApplication.shared) }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .pre(.resigned)]
    )
  }
  
  func testDidEnterBackground() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationDidEnterBackground!(UIApplication.shared) }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .currently(.resigned)]
    )
  }
  
  func testWillFinishLaunching() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          willFinishLaunchingWithOptions: nil
        )
      }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .pre(.active(.first(nil)))]
    )
  }
  
  func testDidFinishLaunching() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didFinishLaunchingWithOptions: nil
        )
      }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .currently(.active(.first(nil)))]
    )
  }
  
  func testWillEnterBackground() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationWillEnterForeground!(UIApplication.shared) }
      .map { $0.session.state }
      ,
      [.currently(.awaitingLaunch), .pre(.active(.some))]
    )
  }
  
  func testSignificantTimeChange() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationSignificantTimeChange!(UIApplication.shared) }
      .map { $0.isObservingSignificantTimeChange }
      ,
      [false, true]
    )
  }
  
  func testMemoryWarning() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationDidReceiveMemoryWarning!(UIApplication.shared) }
      .map { $0.isExperiencingMemoryWarning }
      ,
      [false, true]
    )
  }
  
  func testShouldRequestHealthAuthorization() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationShouldRequestHealthAuthorization!(UIApplication.shared) }
      .map { $0.isExperiencingHealthAuthorizationRequest }
      ,
      [false, true]
    )
  }
  
  func testProtectedDataDidBecomeAvailable() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationProtectedDataDidBecomeAvailable!(UIApplication.shared) }
      .map { $0.isProtectedDataAvailable }
      ,
      [.currently(false), .currently(true)]
    )
  }
  
  func testProtectedDataWillBecomeUnavailable() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall { $0.applicationProtectedDataWillBecomeUnavailable!(UIApplication.shared) }
      .map { $0.isProtectedDataAvailable }
      ,
      [.currently(false), .pre(false)]
    )
  }
  
  func testConversionCallbacks() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didRegister: UIUserNotificationSettingsStub(id: "x")
        )
      }
      .map { $0.userNotificationSettings }
      ,
      [
        .idle,
        .registered(UIUserNotificationSettingsStub(id: "x") as UIUserNotificationSettings)
      ]
    )
  }
  
  func testDidFailToRegisterForRemoteNotifications() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didFailToRegisterForRemoteNotificationsWithError: ErrorStub(id: "x")
        )
      }
      .map { $0.remoteNotificationRegistration }
      ,
      [.idle, .error(ErrorStub(id: "x") as Error)]
    )
  }
  
  func testDidRegisterForRemoteNotifications() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didRegisterForRemoteNotificationsWithDeviceToken: Data()
        )
      }
      .map { $0.remoteNotificationRegistration }
      ,
      [.idle, .some(token: Data())]
    )
  }
  
  func testDidDecodeRestorableState() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didDecodeRestorableStateWith: CoderStub(id: "x")
        )
      }
      .map { $0.stateRestoration }
      ,
      [.idle, .decoding(CoderStub(id: "x"))]
    )
  }
  
  func testWillEncodeRestorableState() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          willEncodeRestorableStateWith: CoderStub(id: "x")
        )
      }
      .map { $0.stateRestoration }
      ,
      [.idle, .encoding(CoderStub(id: "x"))]
    )
  }
  
  func testShouldSaveApplicationStateConsidering() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          shouldSaveApplicationState: CoderStub(id: "x")
        )
      }
      .map { $0.shouldSaveApplicationState }
      ,
      [.idle, .considering(CoderStub(id: "x") as NSCoder)]
    ) // might want to refactor to bool or change default to .allow(true)
  }
  
  func testShouldRestoreApplicationStateConsidering() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          shouldRestoreApplicationState: CoderStub(id: "x")
        )
      }
      .map { $0.shouldRestoreApplicationState }
      ,
      [.idle, .considering(CoderStub(id: "x") as NSCoder)]
    ) // might want to refactor to bool or change default to .allow(true)
  }
  
  func testWillContinueUserActivityWithType() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          willContinueUserActivityWithType: "x"
        )
      }
      .map { $0.userActivityState }
      ,
      [.idle, .willContinue("x")]
    )
  }
  
  func testDidFailToContinueUserActivity() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didFailToContinueUserActivityWithType: "x",
          error: ErrorStub(id: "y")
        )
      }
      .map { $0.userActivityState }
      ,
      [.idle, .failing("x", ErrorStub(id: "y"))]
    )
  }
  
  func testDidUpdateUserActivity() {
    let activity = NSUserActivity(activityType: "x")
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didUpdate: activity
        )
      }
      .map { $0.userActivityState }
      ,
      [.idle, .completing(activity)]
    )
  }
  
  func testContinueUserActivity() {
    let activity = NSUserActivity(activityType: "x")
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          continue: activity,
          restorationHandler: { _ in }
        )
      }
      .map { $0.userActivityState }
      ,
      [.idle, .isContinuing(activity, restoration: { _ in })]
    )
  }
  
  func testWillChangeStatusBarOrientation() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          willChangeStatusBarOrientation: .landscapeLeft,
          duration: 0.0
        )
      }
      .map { $0.statusBarOrientation }
      ,
      [.currently(.unknown), .pre(.landscapeLeft)]
    )
  }
  
  func testDidChangeStatusBarOrientation() {
    // This can fail based on simulator. Needs better solution.
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didChangeStatusBarOrientation: .landscapeLeft
        )
      }
      .map { $0.statusBarOrientation }
      ,
      [.currently(.unknown), .currently(.portrait)]
    )
  }
  
  func testWillChangeStatusBarFrame() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          willChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
        )
      }
      .map { $0.statusBarFrame }
      ,
      [.currently(.zero), .pre(CGRect(x: 1, y: 2, width: 3, height: 4))]
    )
  }
  
  func testDidChangeStatusBarFrame() {
    // Consider adding beginState to -willChange enum option .pre(from: to:)
    // Or firing changes for every frame of animation
    
//    XCTAssertEqual(
//      RxUIApplicationTestCase
//      .statesFrom {
//        $0.application(
//          UIApplication.shared,
//          didChangeStatusBarFrame: CGRect(x: 1, y: 2, width: 3, height: 4)
//        )
//      }
//      .map { $0.statusBarFrame }
//      ,
//      [.none(.zero), .currently(CGRect(x: 0, y: 0, width: 320, height: 20))]
//    )
  }
  
  func testHandleActionWithIdentifierLocal() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          completionHandler: {}
        )
      }
      .map { $0.localAction }
      ,
      [
        .idle,
        .progressing(
          .ios8(
            id: .some( "x"),
            notification: UILocalNotification(),
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfoRemote() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["y":"z"],
          withResponseInfo: ["a":"b"],
          completionHandler: {}
        )
      }
      .map { $0.remoteAction }
      ,
      [
        .idle,
        .progressing(
          .ios9(
            id: .some( "x"),
            userInfo: ["y":"z"],
            responseInfo: ["a":"b"],
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfoRemoteComplete_ios9() {
    var x = RxUIApplicationDelegate.Model.empty
    x.remoteAction = .complete(
      .ios9(
        id: .some( "x"),
        userInfo: ["y":"z"],
        responseInfo: ["a":"b"],
        completion: {}
      )
    )
    XCTAssertEqual(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.remoteAction }
        ,
        [.idle]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfoRemoteComplete_ios8() {
    var x = RxUIApplicationDelegate.Model.empty
    x.remoteAction = .complete(
      .ios8(
        id: .some( "x"),
        userInfo: ["y":"z"],
        completion: {}
      )
    )
    XCTAssertEqual(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.remoteAction }
        ,
        [.idle]
    )
  }
  
  func testHandleActionWithIdentifierRemote() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          forRemoteNotification: ["y":"z"],
          completionHandler: {}
        )
      }
      .map { $0.remoteAction }
      ,
      [
        .idle,
        .progressing(
          .ios8(
            id: .some( "x"),
            userInfo: ["y":"z"],
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionWithIdentifierResponseInfo() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          handleActionWithIdentifier: "x",
          for: UILocalNotification(),
          withResponseInfo: ["y":"z"],
          completionHandler: {}
        )
      }
      .map { $0.localAction }
      ,
      [
        .idle,
        .progressing(
          .ios9(
            id: .some( "x"),
            notification: UILocalNotification(),
            response: ["y":"z"],
            completion: {}
          )
        )
      ]
    )
  }
  
  func testHandleActionLocalComplete_ios9() {
    var x = RxUIApplicationDelegate.Model.empty
    x.localAction = .complete(
      .ios9(
        id: .defaultAction,
        notification: UILocalNotification(),
        response: ["a":"b"],
        completion: {}
      )
    )
    XCTAssertEqual(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.localAction }
        ,
        [.idle]
    )
  }
  
  func testHandleActionLocalComplete_ios8() {
    var x = RxUIApplicationDelegate.Model.empty
    x.localAction = .complete(
      .ios8(
        id: .defaultAction,
        notification: UILocalNotification(),
        completion: {}
      )
    )
    XCTAssertEqual(
      RxUIApplicationTestCase
        .statesFrom(stream: .just(x))
        .map { $0.localAction }
        ,
        [.idle]
    )
  }
  
  func testPerformActionForShortcutAction() {
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFromCall(
        initial: RxUIApplicationDelegate.Model.empty.with(
          shortcutItem: RxUIApplicationDelegate.Model.ShortcutAction(
            item: .stub,
            state: .idle
          )
        ),
        call: {
          $0.application!(
            UIApplication.shared,
            performActionFor: .stub,
            completionHandler: { _ in }
          )
        }
      )
      .map { $0.shortcutActions }
      .flatMap { $0 }
      ,
      [
        RxUIApplicationDelegate.Model.ShortcutAction(
          item: .stub,
          state: .idle
        ),
        RxUIApplicationDelegate.Model.ShortcutAction(
          item: .stub,
          state: .progressing({ _ in })
        )
      ]
    )
  }
  
  func testHandleEventsForBackgroundURLSession() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "x",
          completionHandler: {}
        )
      }
      .map { $0.backgroundURLSessions }
      .flatMap { $0 }
      ,
      [
        RxUIApplicationDelegate.Model.BackgroundURLSessionAction(
          id: "x",
          completion: {},
          state: .progressing
        )
      ]
    )
  }
  
  func testDidReceiveRemoteNotification() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          didReceiveRemoteNotification: ["x":"y"],
          fetchCompletionHandler: { _ in }
        )
      }
      .map { $0.remoteNotifications }
      .flatMap { $0 }
      ,
      [
        RxUIApplicationDelegate.Model.RemoteNofitication(
          notification: ["x":"y"],
          state: .progressing({ _ in })
        )
      ]
    )
  }
  
  func testHandlewatchKitExtensionRequestsProgressing() {
    XCTAssertEqual(
      RxUIApplicationTestCase
        .statesFromCall {
          $0.application!(
            UIApplication.shared,
            handleWatchKitExtensionRequest: ["x":"y"],
            reply: { _ in }
          )
        }
        .map { $0.watchKitExtensionRequests }
        .flatMap { $0 }
      ,
      [
        RxUIApplicationDelegate.Model.watchKitExtensionRequests(
          completion: { _ in },
          state: .progressing(
            info: ["x":"y"]
          )
        )
      ]
    )
  }
  
  func testHandlewatchKitExtensionRequestsResponding() {
    var x = RxUIApplicationDelegate.Model.empty
    x.watchKitExtensionRequests = [
      RxUIApplicationDelegate.Model.watchKitExtensionRequests(
        completion: { _ in },
        state: .responding(
          response: ["x":"y"]
        )
      )
    ]
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.watchKitExtensionRequests }
        .flatMap { $0 },
      []
    )
  }
  
  func testShouldAllowExtensionPointIdentifier() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          shouldAllowExtensionPointIdentifier: .keyboard
        )
      }
      .map { $0.extensionPointIdentifier }
      ,
      [.idle, .considering(.keyboard)]
    )
  }
  
  func testSupportedInterfaceOrientationsFor() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        $0.application!(
          UIApplication.shared,
          supportedInterfaceOrientationsFor: WindowStub(id: "x")
        )
      }
      .map { $0.interfaceOrientations }
      .flatMap { $0 }
      ,
      [.considering(WindowStub(id: "x") as UIWindow)]
    )
  }
  
  func testViewControllerWithRestorationIdentifierPathConsidering() {
    XCTAssertEqual(
      RxUIApplicationTestCase
      .statesFromCall {
        let x = $0.application!(
          UIApplication.shared,
          viewControllerWithRestorationIdentifierPath: ["x"],
          coder: CoderStub(id: "y")
        )
        return x ?? {}
      }
      .map { $0.viewControllerRestoration }
      ,
      [
        .idle,
        .considering(
          RxUIApplicationDelegate.Model.RestorationQuery(
            identifier: "x",
            coder: CoderStub(id: "y") as NSCoder
          )
        )
      ]
    )
  }
  
  func testWillFinishLaunchingWithOptionsFalse() {
    
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { latest in
            switch latest.session.state {
            case .pre(let a):
              switch a {
              case .active(.first):
                var new = latest
                new.shouldLaunch = false
                return new
              default:
                return latest
              }
            default:
              return latest
            }
          }
      }
    )
    
    XCTAssertFalse(
      delegate.application(
        UIApplication.shared,
        willFinishLaunchingWithOptions: [:]
      )
    )
    
    let _ = cycle // necessary to retain
  }
  
  func testShouldOpenURLs4() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )

    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if
              case .considering(let query) = model.urlActionIncoming,
              case .ios4(let URL, _, _) = query {
              new.urlActionIncoming = .allowing(URL)
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        open: URL(string: "https://www.duckduckgo.com")!,
        sourceApplication: "x",
        annotation: [:]
      )
      ,
      true
    )
    
    let _ = cycle
  }
  
  func testShouldOpenURLs9() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if
              case .considering(let query) = model.urlActionIncoming,
              case .ios9(let URL, _) = query {
              new.urlActionIncoming = .allowing(URL)
            }
            return new
        }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        open: URL(string: "https://www.duckduckgo.com")!,
        options: [:]
      )
      ,
      true
    )
    
    let _ = cycle
  }

  func testSupportedInterfaceOrientations() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            new.interfaceOrientations = model.interfaceOrientations.map {
              switch $0 {
              case .considering(let window):
                return .allowing(
                  RxUIApplicationDelegate.Model.WindowResponse(
                    window: window,
                    orientation: .portraitUpsideDown
                  )
                )
              default:
                return $0
              }
            }
            return new
        }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        supportedInterfaceOrientationsFor: WindowStub(id: "x")
      )
      ,
      .portraitUpsideDown
    )
    
    let _ = cycle
  }
  
  func testextensionPointIdentifier() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if case .considering(let ID) = model.extensionPointIdentifier {
              new.extensionPointIdentifier = .allowing(ID)
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        shouldAllowExtensionPointIdentifier: .keyboard
      )
      ,
      true
    )
    
    let _ = cycle
  }
  
  func testViewControllerWithRestorationIdentifierPathAllowing() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if case .considering(let query) = new.viewControllerRestoration {
              new.viewControllerRestoration = .allowing(
                RxUIApplicationDelegate.Model.RestorationResponse(
                  identifier: query.identifier,
                  view: ViewControllerStub(id: "x")
                )
              )
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        viewControllerWithRestorationIdentifierPath: ["y"],
        coder: CoderStub(id: "z")
      )
      ,
      ViewControllerStub(id: "x")
    )
    
    let _ = cycle
  }
  
  func testShouldSaveApplicationStateAllowing() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if case .considering(_) = model.shouldSaveApplicationState {
              new.shouldSaveApplicationState = .allowing(true)
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        shouldSaveApplicationState: CoderStub(id: "x")
      )
      ,
      true
    )
    
    let _ = cycle
  }
  
  func testShouldRestoreApplicationStateAllowing() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if case .considering(_) = model.shouldRestoreApplicationState {
              new.shouldRestoreApplicationState = .allowing(true)
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        shouldRestoreApplicationState: CoderStub(id: "x")
      )
      ,
      true
    )
    
    let _ = cycle
  }
  
  func testShouldNotifyUserActivitiesWithTypes() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if case .willContinue(let type) = model.userActivityState {
              new.userActivityState = .shouldNotifyUserActivitiesWithType(type)
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        willContinueUserActivityWithType: "x"
      )
      ,
      true
    )
    
    let _ = cycle
  }
  
  func testActivitiesWithAvaliableData() {
    let delegate = RxUIApplicationDelegate(
      initial: .empty
    )
    
    let cycle = Cycled(
      seed: RxUIApplicationDelegate.Model.empty,
      transform: { model in
        delegate
          .eventsCapturedAfterRendering(model)
          .map { model -> RxUIApplicationDelegate.Model in
            var new = model
            if case .isContinuing(let activity) = model.userActivityState {
              new.userActivityState = .hasAvailableData(activity.0)
            }
            return new
          }
      }
    )
    
    let _ = delegate.application(
      UIApplication.shared,
      willFinishLaunchingWithOptions: [:]
    )
    
    XCTAssertEqual(
      delegate.application(
        UIApplication.shared,
        continue: NSUserActivity(activityType: "x"),
        restorationHandler: { _ in }
      )
      ,
      true
    )
    
    let _ = cycle
  }
  
  func testMomentaryState() {
    var x = RxUIApplicationDelegate.Model.empty
    x.isExperiencingHealthAuthorizationRequest = true

    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.isExperiencingHealthAuthorizationRequest }
      ,
      [false]
    )
  }
  
  func testRenderingIsIgnoringUserEvents() {

    let x = RxUIApplicationDelegate.Model.empty
    var y = x; y.isIgnoringUserEvents = true
    
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(y))
      .map { $0.isIgnoringUserEvents }
      ,
      [
        true
      ]
    )
  }
  
  func testRenderingIsIdleTimerDisabled() {
    
    let x = RxUIApplicationDelegate.Model.empty
    var y = x; y.isIdleTimerDisabled = true
    
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(y))
      .map { $0.isIdleTimerDisabled }
      ,
      [
        true
      ]
    )
  }

  func testRenderingURLActionOutgoingOpening() {
    var x = RxUIApplicationDelegate.Model.empty
    x.urlActionOutgoing = .attempting(URL(string: "https://www.duckduckgo.com")!)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.urlActionOutgoing }
      ,
      [.opening(URL(string: "https://www.duckduckgo.com")!)]
    )
  }
  
  func testRenderingURLActionOutgoingIdle() {
    var x = RxUIApplicationDelegate.Model.empty
    x.urlActionOutgoing = .opening(URL(string: "https://www.duckduckgo.com")!)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.urlActionOutgoing }
      ,
      [.idle]
    )
  }
  
  func testRenderingSendActionSending() {
    let action = RxUIApplicationDelegate.Model.TargetAction(
      action: #selector(getter: UIApplication.isIdleTimerDisabled),
      target: UIApplication.shared,
      sender: nil,
      event: nil
    )
    var x = RxUIApplicationDelegate.Model.empty
    x.targetAction = .sending(action)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.targetAction }
      ,
      [.responding(action, true)]
    )
  }
  
  func testRenderingSendActionIdle() {
    let action = RxUIApplicationDelegate.Model.TargetAction(
      action: #selector(getter: UIApplication.isIdleTimerDisabled),
      target: UIApplication.shared,
      sender: nil,
      event: nil
    )
    var x = RxUIApplicationDelegate.Model.empty
    x.targetAction = .responding(action, true)
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.targetAction }
      ,
      [.idle]
    )
  }
  
  func testRenderingBackgroundTasksProgressing() {
    var y = RxUIApplicationDelegate.Model.empty
    y.backgroundTasks = [
      RxUIApplicationDelegate.Model.BackgroundTask(
        name: "x",
        state: .pending
      )
    ]
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(y))
      .map { $0.backgroundTasks }
      .flatMap { $0 }
      // This test will occasionally fail due to harcoded UIBackgroundTaskIdentifier.
      // Needs better solution
      ,
      [
        RxUIApplicationDelegate.Model.BackgroundTask(
          name: "x",
          state: .progressing(UIBackgroundTaskIdentifier(rawValue: 1))
        )
      ]
    )
  }
  
  func testRenderingBackgroundTasksComplete() {
    var y = RxUIApplicationDelegate.Model.empty
    y.backgroundTasks = [
      RxUIApplicationDelegate.Model.BackgroundTask(
        name: "x",
        state: .complete(UIBackgroundTaskIdentifier(rawValue: 1))
      )
    ]
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(y))
      .map { $0.backgroundTasks }
      .flatMap { $0 }
      ,
      []
    )
  }
  
  func testRenderingBackgroundFetchProgressCallback() {
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFromCall(call: {
        $0.application!(
          UIApplication.shared,
          performFetchWithCompletionHandler: { _ in }
        )
      })
      .map { $0.backgroundFetch }
      ,
      [
        RxUIApplicationDelegate.Model.BackgroundFetch(
          minimumInterval: .never,
          state: .idle
        ),
        RxUIApplicationDelegate.Model.BackgroundFetch(
          minimumInterval: .never,
          state: .progressing({ _ in})
        )
      ]
    )
  }
  
  func testRenderingBackgroundFetchComplete() {
    var x = RxUIApplicationDelegate.Model.empty
    x.backgroundFetch = RxUIApplicationDelegate.Model.BackgroundFetch(
      minimumInterval: .never,
      state: .complete(.noData, { _ in})
    )
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
      .map { $0.backgroundFetch }
      ,
      [
        RxUIApplicationDelegate.Model.BackgroundFetch(
          minimumInterval: .never,
          state: .idle
        )
      ]
    )
  }
  
  func testRenderingBackgroundURLSessionActionProgressing() {
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFromCall {
        $0.application!(
          UIApplication.shared,
          handleEventsForBackgroundURLSession: "id",
          completionHandler: {}
        )
      }
      .map { $0.backgroundURLSessions }
      .flatMap { $0 }
      ,
      [
        RxUIApplicationDelegate.Model.BackgroundURLSessionAction(
          id: "id",
          completion: {},
          state: .progressing
        )
      ]
    )
  }
  
  func testRenderingBackgroundURLSessionActionComplete() {
    var x = RxUIApplicationDelegate.Model.empty
    x.backgroundURLSessions = Set([
      RxUIApplicationDelegate.Model.BackgroundURLSessionAction(
        id: "id",
        completion: {},
        state: .complete
      )
    ])
    XCTAssertEqual(
      RxUIApplicationTestCase.statesFrom(stream: .just(x))
        .map { $0.backgroundURLSessions }
        .flatMap { $0 }
      ,
      []
    )
  }
  
  func testDictionaryConcatenation() {
    XCTAssertEqual(
      [WindowStub(id: "x"): UIInterfaceOrientationMask.allButUpsideDown] +
      [WindowStub(id: "y"): UIInterfaceOrientationMask.allButUpsideDown]
      ,
      [WindowStub(id: "y"): UIInterfaceOrientationMask.allButUpsideDown,
      WindowStub(id: "x"): UIInterfaceOrientationMask.allButUpsideDown]
    )
  }
  
  func testDictionaryMerging() {
    let same = WindowStub(id: "x")
    XCTAssertEqual(
      [same: UIInterfaceOrientationMask.allButUpsideDown] +
      [same: UIInterfaceOrientationMask.allButUpsideDown]
      ,
      [same: UIInterfaceOrientationMask.allButUpsideDown]
    )
  }
  
  func testDictionaryMergeOverwrite() {
    let same = WindowStub(id: "x")
    XCTAssertEqual(
      [same: UIInterfaceOrientationMask.allButUpsideDown] +
      [same: UIInterfaceOrientationMask.portraitUpsideDown]
      ,
      [same: UIInterfaceOrientationMask.allButUpsideDown]
    )
  }
  
  func testAdditions() {
    let x = ["x"]
    let y: [String] = []
    let z = RxUIApplicationDelegate.additions(new: x, old: y)
    XCTAssertEqual(z.count, 1)
  }
  
  func testDeletions() {
    let x = ["x"]
    let y: [String] = []
    let z = RxUIApplicationDelegate.deletions(old: x, new: y)
    XCTAssertEqual(z.count, 1)
  }
  
  func testCompletedBackgroundIDs() {
    let x = [RxUIApplicationDelegate.Model.BackgroundTask(
      name: "x",
      state: .complete(UIBackgroundTaskIdentifier(rawValue: 2017))
    )]
    let z = x.compactMap { $0.ID }
    XCTAssertEqual(z, [UIBackgroundTaskIdentifier(rawValue: 2017)])
  }
  
  func testDeletedBackgroundTaskIDs() {
    let x = [RxUIApplicationDelegate.Model.BackgroundTask(
      name: "x",
      state: .progressing(UIBackgroundTaskIdentifier(rawValue: 2017))
    )]
    let y: [RxUIApplicationDelegate.Model.BackgroundTask] = []
    let z = RxUIApplicationDelegate.deletions(old: x, new: y).compactMap { $0.ID }
    XCTAssertEqual(z, [UIBackgroundTaskIdentifier(rawValue: 2017)])
  }

  struct ErrorStub: Error, Equatable {
    let id: String
    static func ==(left: ErrorStub, right: ErrorStub) -> Bool {
      return left.id == right.id
    }
  }
  
  class CoderStub: NSCoder {
    let id: String
    init(id: String) {
      self.id = id
      super.init()
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? CoderStub { return
        other.id == id
      } else { return
        false
      }
    }
  }
  
  class UIUserNotificationSettingsStub: UIUserNotificationSettings {
    let id: String
    init(id: String) {
      self.id = id
      super.init()
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? UIUserNotificationSettingsStub { return
        other.id == id
      } else { return
        false
      }
    }
  }
  
  class WindowStub: UIWindow {
    let id: String
    init(id: String) {
      self.id = id
      super.init(frame: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? WindowStub { return
        other.id == id
      } else { return
        false
      }
    }
    override var hashValue: Int {
      return id.hashValue
    }
    override var debugDescription: String {
      return id
    }
  }
  
  class ViewControllerStub: UIViewController {
    let id: String
    init(id: String) {
      self.id = id
      super.init(nibName: "", bundle: nil)
    }
    required init?(coder aDecoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
    override func isEqual(_ object: Any?) -> Bool {
      if let other = object as? ViewControllerStub {
        return other.id == id
      } else {
        return false
      }
    }
  }
}

extension RxUIApplicationDelegate.Model {
  func with(shortcutItem: RxUIApplicationDelegate.Model.ShortcutAction) -> RxUIApplicationDelegate.Model {
    var edit = self
    edit.shortcutActions += [shortcutItem]
    return edit
  }
}

func ==<T: Equatable>(left: [T?], right: [T?]) -> Bool { return
  left.count == right.count &&
  zip(left, right).first { $0 != $1 } == nil
}

extension UIApplicationShortcutItem {
  static var stub: UIApplicationShortcutItem { return
    UIApplicationShortcutItem(
      type: "x",
      localizedTitle: "y"
    )
  }
}

extension UIViewController {
  public static var empty: UIViewController {
    let x = UIViewController()
    x.view.backgroundColor = .white
    return x
  }
}

public final class Cycled<T> {
  private var output: Observable<T>?
  private var inputProxy: ReplaySubject<T>?
  private let cleanup = DisposeBag()
  public required init(seed: T, transform: (Observable<T>) -> Observable<T>) {
    inputProxy = ReplaySubject.create(
      bufferSize: 1
    )
    output = transform(inputProxy!)
    // `.startWith` is redundant, but necessary to kickoff cycle
    // Possibly removed if `output` was BehaviorSubject?
    // Not sure how to `merge` observables to single BehaviorSubject though.
    output?
      .debug()
      .startWith(seed)
      .subscribe(self.inputProxy!.on)
      .disposed(by: cleanup)
  }
}
