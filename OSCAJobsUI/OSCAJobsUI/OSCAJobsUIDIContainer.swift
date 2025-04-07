//
//  OSCAJobsUIDIContainer.swift
//  OSCAPressReleaseUI
//
//  Created by Stephan Breidenbach on 28.04.21.
//  Reviewed by Stephan Breidenbach on 27.01.22
//

import Foundation
import OSCAEssentials
import OSCANetworkService
import OSCAJobs
import OSCASafariView

/**
 Every isolated module feature will have its own Dependency Injection Container,
 to have one entry point where we can see all dependencies and injections of the module
 */
final class OSCAJobsUIDIContainer {
  let dependencies: OSCAJobsUIDependencies
  
  public init(dependencies: OSCAJobsUIDependencies) {
#if DEBUG
    print("\(String(describing: Self.self)): \(#function)")
#endif
    self.dependencies = dependencies
  } // end init
} // end final class OSCAJobsUIDIContainer

extension OSCAJobsUIDIContainer: OSCAJobsFlowCoordinatorDependencies {
  // MARK: - Jobs Main
  func makeOSCAJobsMainViewController(actions: OSCAJobsMainViewModelActions) -> OSCAJobsMainViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    return OSCAJobsMainViewController.create(with: makeOSCAJobsMainViewModel(actions: actions))
  } // end makeJobsViewController
  
  func makeOSCAJobsMainViewModel(actions: OSCAJobsMainViewModelActions) -> OSCAJobsMainViewModel {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    
    return OSCAJobsMainViewModel(dataModule: dependencies.dataModule, actions: actions)
  } // end func makeJobsViewModel
  
  // MARK: - Jobs Detail
  
  
  // MARK: - Flow Coordinators
  func makeSafariViewFlowCoordinator(router: Router, url: URL) -> OSCASafariViewFlowCoordinator {
    return dependencies.webViewModule.getSafariViewFlowCoordinator(router: router, url: url)
  }// end func makeSafariViewFlowCoordinator
  
  func makeJobsFlowCoordinator(router: Router) -> OSCAJobsFlowCoordinator {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    return OSCAJobsFlowCoordinator(router: router, dependencies: self)
  } // end func makeJobsFlowCoordinator
} // end extension class OSCAJobsUIDIContainer
