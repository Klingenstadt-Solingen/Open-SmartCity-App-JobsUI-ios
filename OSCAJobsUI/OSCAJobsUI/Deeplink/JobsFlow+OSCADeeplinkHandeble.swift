//
//  JobsFlow+OSCADeeplinkHandeble.swift
//  OSCAJobsUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//

import Foundation
import OSCAEssentials

extension OSCAJobsFlowCoordinator: OSCADeeplinkHandeble {
  ///```console
  ///xcrun simctl openurl booted \
  /// "solingen://jobs/detail?object=lwMRGTHnJW"
  /// ```
  public func canOpenURL(_ url: URL) -> Bool {
    let deeplinkScheme: String = dependencies
      .deeplinkScheme
    return url.absoluteString.hasPrefix("\(deeplinkScheme)://jobs")
  }// end public func canOpenURL
  
  public func openURL(_ url: URL,
                      onDismissed:(() -> Void)?) throws -> Void {
    guard canOpenURL(url)
    else { return }
    let deeplinkParser = DeeplinkParser()
    if let payload = deeplinkParser.parse(content: url) {
      switch payload.target {
      case "detail":
        let objectId = payload.parameters["object"]
        showJobsMain(with: objectId,
                     onDismissed: onDismissed)
      default:
        showJobsMain(animated: true,
                     onDismissed: onDismissed)
      }
    } else {
      showJobsMain(animated: true,
                   onDismissed: onDismissed)
    }// end if
  }// end public func openURL
  
  func showJobsMain(with objectId: String? = nil,
                    onDismissed:(() -> Void)?) -> Void {
#if DEBUG
    print("\(String(describing: self)): \(#function): objectId: \(objectId ?? "NIL")")
#endif
    /// is there an object id?
    if let objectId = objectId {
      /// is there a jobs main view controller
      if let jobsMainVC = jobsMainVC {
        jobsMainVC.didReceiveDeeplinkDetail(with: objectId)
      } else {
        showJobsMain(animated: true,
                     onDismissed: onDismissed)
        guard let jobsMainVC = jobsMainVC
        else { return }
        jobsMainVC.didReceiveDeeplinkDetail(with: objectId)
      }// end if
    }// end
  }// end public func showJobsMain
}// end extension final class OSCAJobsFlowCoordinator
