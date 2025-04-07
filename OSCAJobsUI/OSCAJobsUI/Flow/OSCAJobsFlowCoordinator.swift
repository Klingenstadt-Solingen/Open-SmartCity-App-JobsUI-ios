//
//  OSCAJobsFlowCoordinator.swift
//
//
//  Created by Stephan Breidenbach on 21.01.22.
//

import Foundation
import OSCAEssentials
import OSCAJobs
import OSCASafariView

public protocol OSCAJobsFlowCoordinatorDependencies {
  var deeplinkScheme: String { get }
  func makeOSCAJobsMainViewController(actions: OSCAJobsMainViewModelActions) -> OSCAJobsMainViewController
  func makeSafariViewFlowCoordinator(router: Router, url: URL) -> OSCASafariViewFlowCoordinator
} // end protocol OSCAJobsFlowCoordinatorDependencies

public final class OSCAJobsFlowCoordinator: Coordinator {
  /**
   `children`property for conforming to `Coordinator` protocol is a list of `Coordinator`s
   */
  public var children: [Coordinator] = []
  
  /**
   router injected via initializer: `router` will be used to push and pop view controllers
   */
  public let router: Router
  
  /**
   dependencies injected via initializer DI conforming to the `OSCAJobsFlowCoordinatorDependencies` protocol
   */
  let dependencies: OSCAJobsFlowCoordinatorDependencies
  
  /**
   jobs main view controller `OSCAJobsMainViewController`
   */
  weak var jobsMainVC: OSCAJobsMainViewController?
  weak var webViewFlow: Coordinator?
  
  public init(router: Router,
              dependencies: OSCAJobsFlowCoordinatorDependencies
  ) {
    self.router = router
    self.dependencies = dependencies
  } // end init router, dependencies
  
  // MARK: - Jobs Detail
  
  private func showJobsDetail(job: OSCAJobPosting) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    if let url = URL(string: job.url ?? "") {
      if let webViewFlow = self.webViewFlow {
        removeChild(webViewFlow)
        self.webViewFlow = nil
      }// end if
      let flow = self.dependencies.makeSafariViewFlowCoordinator(router: self.router, url: url)
      presentChild(flow, animated: true){
#if DEBUG
        print("\(String(describing: self)): \(#function)")
#endif
      }// end on dismissed closure
      self.webViewFlow = flow
    }// end if
  } // end private func showJobsDetail
  
  // MARK: - Jobs Main
  
  public func showJobsMain(animated: Bool,
                           onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    // Note: here we keep strong reference with actions, this way this flow do not need to be strong referenced
    let actions: OSCAJobsMainViewModelActions = OSCAJobsMainViewModelActions(
      showJobsDetail: showJobsDetail
    ) // end let actions
    // instantiate view controller
    let vc = dependencies.makeOSCAJobsMainViewController(actions: actions)
    router.present(vc,
                   animated: animated,
                   onDismissed: onDismissed)
    jobsMainVC = vc
  } // end public func showJobsMain
  
  public func present(animated: Bool, onDismissed: (() -> Void)?) {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    showJobsMain(animated: animated, onDismissed: onDismissed)
  } // end func present
} // end final class OSCAJobsFlowCoordinator

extension OSCAJobsFlowCoordinator {
  /**
   add `child` `Coordinator`to `children` list of `Coordinator`s and present `child` `Coordinator`
   */
  public func presentChild(_ child: Coordinator,
                           animated: Bool,
                           onDismissed: (() -> Void)? = nil) {
    self.children.append(child)
    child.present(animated: animated) { [weak self, weak child] in
      guard let self = self, let child = child else { return }
      self.removeChild(child)
      onDismissed?()
    } // end on dismissed closure
  } // end public func presentChild
  
  private func removeChild(_ child: Coordinator) {
    /// `children` includes `child`!!
    guard let index = children.firstIndex(where: { $0 === child }) else { return } // end guard
    children.remove(at: index)
  } // end private func removeChild
} // end extension public final class OSCAJobsFlowCoordinator
