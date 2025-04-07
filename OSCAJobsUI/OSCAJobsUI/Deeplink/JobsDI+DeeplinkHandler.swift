//
//  JobsDI+DeeplinkHandler.swift
//  OSCAJobsUI
//
//  Created by Stephan Breidenbach on 08.09.22.
//

import Foundation
extension OSCAJobsUIDIContainer {
  var deeplinkScheme: String {
    return self
      .dependencies
      .moduleConfig
      .deeplinkScheme
  }// end var deeplinkScheme
}// end extension final class OSCAJobsUIDIContainer
