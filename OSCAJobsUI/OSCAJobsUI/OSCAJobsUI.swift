//
//  OSCAJobsUI.swift
//  OSCAJobsUI
//
//  Created by Mammut Nithammer on 10.01.22.
//  reviewed by Stephan Breidenbach on 26.08.2022
//

import OSCAEssentials
import OSCAJobs
import UIKit
import OSCASafariView

public protocol OSCAJobsUIModuleConfig: OSCAUIModuleConfig {
  var shadowSettings: OSCAShadowSettings { get set }
  var placeholderImage: UIImage? { get set }
  var cornerRadius: Double { get set }
  var deeplinkScheme: String { get set }
} // end public protocol OSCAJobsUIModuleConfig

public struct OSCAJobsUIDependencies {
  let dataModule: OSCAJobs
  let moduleConfig: OSCAJobsUIModuleConfig
  let analyticsModule: OSCAAnalyticsModule?
  let webViewModule: OSCASafariView
  
  public init(dataModule: OSCAJobs,
              moduleConfig: OSCAJobsUIModuleConfig,
              analyticsModule: OSCAAnalyticsModule? = nil,
              webViewModule: OSCASafariView
  ) {
    self.dataModule = dataModule
    self.moduleConfig = moduleConfig
    self.analyticsModule = analyticsModule
    self.webViewModule = webViewModule
  } // end public init
} // end public Struct OSCAJobsUIDependencies

/**
 The configuration of the `OSCAJobsUI`-module
 */
public struct OSCAJobsUIConfig: OSCAJobsUIModuleConfig {
  /// module title
  public var title: String?
  public var externalBundle: Bundle?
  public var shadowSettings: OSCAShadowSettings
  public var placeholderImage: UIImage?
  /// Returns a modified HTML-String.
  public var cornerRadius: Double
  public var fontConfig: OSCAFontConfig
  public var colorConfig: OSCAColorConfig
  /// app deeplink scheme URL part before `://`
  public var deeplinkScheme      : String = "solingen"
  
  /// Initializer for `OSCAJobsUIConfig`
  /// - Parameters:
  ///  - title:
  ///  - shadowSettings:
  ///  - placeholderImage: .
  ///  - cornerRadius: .
  ///  - fontConfig
  ///  - colorConfig: .
  ///  - deeplinkScheme:
  public init(title: String?,
              externalBundle: Bundle? = nil,
              shadowSettings: OSCAShadowSettings,
              cornerRadius: Double,
              placeholderImage: UIImage? = nil,
              fontConfig: OSCAFontConfig,
              colorConfig: OSCAColorConfig,
              deeplinkScheme: String = "solingen") {
    self.title = title
    self.externalBundle = externalBundle
    self.shadowSettings = shadowSettings
    self.cornerRadius = cornerRadius
    self.placeholderImage = placeholderImage
    self.fontConfig = fontConfig
    self.colorConfig = colorConfig
    self.deeplinkScheme = deeplinkScheme
  } // end public memberwise init
} // end public struct OSCAJobsUIConfig

public struct OSCAJobsUI: OSCAUIModule {
  /// module DI container
  private var moduleDIContainer: OSCAJobsUIDIContainer!
  public var version: String = "1.0.3"
  public var bundlePrefix: String = "de.osca.jobs.ui"
  
  public internal(set) static var configuration: OSCAJobsUIConfig!
  /// module `Bundle`
  ///
  /// **available after module initialization only!!!**
  public internal(set) static var bundle: Bundle!
  
  /**
   create module and inject module dependencies
   - Parameter mduleDependencies: module dependencies
   */
  public static func create(with moduleDependencies: OSCAJobsUIDependencies) -> OSCAJobsUI {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    var module: Self = Self(config: moduleDependencies.moduleConfig)
    module.moduleDIContainer = OSCAJobsUIDIContainer(dependencies: moduleDependencies)
    return module
  } // end public static func create with module dependencies
  
  /// public initializer with module configuration
  /// - Parameter config: module configuration
  public init(config: OSCAUIModuleConfig) {
#if SWIFT_PACKAGE
    Self.bundle = Bundle.module
#else
    guard let bundle: Bundle = Bundle(identifier: bundlePrefix) else { fatalError("Module bundle not initialized!") }
    Self.bundle = bundle
#endif
    guard let extendedConfig = config as? OSCAJobsUIConfig else { fatalError("Config couldn't be initialized!") }
    OSCAJobsUI.configuration = extendedConfig
  } // end public init
} // end public struct OSCAJobsUI

// MARK: - public ui module interface

extension OSCAJobsUI {
  /**
   public module interface `getter`for `OSCAJobsFlowCoordinator`
   - Parameter router: router needed or the navigation graph
   */
  public func getJobsFlowCoordinator(router: Router) -> OSCAJobsFlowCoordinator {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let flow = moduleDIContainer.makeJobsFlowCoordinator(router: router)
    return flow
  } // end public func getJobsFlowCoordinator
  
  /// public module interface `getter` for `OSCAJobsMainViewModel`
  public func getJobsMainViewModel(actions: OSCAJobsMainViewModelActions) -> OSCAJobsMainViewModel {
    let viewModel = moduleDIContainer.makeOSCAJobsMainViewModel(actions: actions)
    return viewModel
  } // end public func getJobsMainViewModel
} // end extension OSCAJobsUI
