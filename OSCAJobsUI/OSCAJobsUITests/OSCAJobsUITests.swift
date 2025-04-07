// Reviewed by Stephan Breidenbach on 21.06.22
#if canImport(XCTest) && canImport(OSCATestCaseExtension)
import XCTest
@testable import OSCAJobsUI
@testable import OSCAJobs
import OSCAEssentials
import OSCATestCaseExtension
import OSCASafariView

final class OSCAJobsUITests: XCTestCase {
  static let moduleVersion = "1.0.3"
  override func setUpWithError() throws {
    try super.setUpWithError()
  }// end override fun setUp
  
  func testModuleInit() throws -> Void {
    let uiModule = try makeDevUIModule()
    XCTAssertNotNil(uiModule)
    XCTAssertEqual(uiModule.version, OSCAJobsUITests.moduleVersion)
    XCTAssertEqual(uiModule.bundlePrefix, "de.osca.jobs.ui")
    let bundle = OSCAJobs.bundle
    XCTAssertNotNil(bundle)
    let uiBundle = OSCAJobsUI.bundle
    XCTAssertNotNil(uiBundle)
    let configuration = OSCAJobsUI.configuration
    XCTAssertNotNil(configuration)
    XCTAssertNotNil(self.devPlistDict)
    XCTAssertNotNil(self.productionPlistDict)
  }// end func testModuleInit
  
  func testContactUIConfiguration() throws -> Void {
    let _ = try makeDevUIModule()
    let uiModuleConfig = try makeUIModuleConfig()
    XCTAssertEqual(OSCAJobsUI.configuration.title, uiModuleConfig.title)
    XCTAssertEqual(OSCAJobsUI.configuration.colorConfig.accentColor, uiModuleConfig.colorConfig.accentColor)
    XCTAssertEqual(OSCAJobsUI.configuration.fontConfig.bodyHeavy, uiModuleConfig.fontConfig.bodyHeavy)
  }// end func testEventsUIConfiguration
}// end final class OSCAJobsUITests

// MARK: - factory methods
extension OSCAJobsUITests {
  public func makeDevModuleDependencies() throws -> OSCAJobsDependencies {
    let networkService = try makeDevNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.jobs.ui")
    let dependencies = OSCAJobsDependencies(
      networkService: networkService,
      userDefaults: userDefaults)
    return dependencies
  }// end public func makeDevModuleDependencies
  
  public func makeDevModule() throws -> OSCAJobs {
    let devDependencies = try makeDevModuleDependencies()
    // initialize module
    let module = OSCAJobs.create(with: devDependencies)
    return module
  }// end public func makeDevModule
  
  public func makeProductionModuleDependencies() throws -> OSCAJobsDependencies {
    let networkService = try makeProductionNetworkService()
    let userDefaults   = try makeUserDefaults(domainString: "de.osca.jobs.ui")
    let dependencies = OSCAJobsDependencies(
      networkService: networkService,
      userDefaults: userDefaults)
    return dependencies
  }// end public func makeProductionModuleDependencies
  
  public func makeProductionModule() throws -> OSCAJobs {
    let productionDependencies = try makeProductionModuleDependencies()
    // initialize module
    let module = OSCAJobs.create(with: productionDependencies)
    return module
  }// end public func makeProductionModule
  
  public func makeUIModuleConfig() throws -> OSCAJobsUIConfig {
    return OSCAJobsUIConfig(title: "OSCAJobsUI",
                                     shadowSettings: OSCAShadowSettings(opacity: 0.2,
                                                                        radius: 10,
                                                                        offset: CGSize(width: 0, height: 2)),
                                     cornerRadius: 10.0,
                                     placeholderImage: UIImage(named: "jobs_placeholder"),
                                     fontConfig: OSCAFontSettings(),
                                     colorConfig: OSCAColorSettings())
  }// end public func makeUIModuleConfig
  
  public func makeWebViewModule() throws -> OSCASafariView {
    let moduleConfig = OSCASafariView.Config(title: "OSCASafariView",
                                             fontConfig: OSCAFontSettings(),
                                             colorConfig: OSCAColorSettings())
    let dependencies = OSCASafariView.Dependencies(moduleConfig: moduleConfig)
    let webViewModule = OSCASafariView.create(with: dependencies)
    return webViewModule
  }// end public func makeWebViewModule
  
  public func makeDevUIModuleDependencies() throws -> OSCAJobsUIDependencies {
    let module      = try makeDevModule()
    let uiConfig    = try makeUIModuleConfig()
    let webViewModule = try makeWebViewModule()
    return OSCAJobsUIDependencies( dataModule: module,
                                   moduleConfig: uiConfig,
                                   webViewModule: webViewModule)
  }// end public func makeDevUIModuleDependencies
  
  public func makeDevUIModule() throws -> OSCAJobsUI {
    let devDependencies = try makeDevUIModuleDependencies()
    // init ui module
    let uiModule = OSCAJobsUI.create(with: devDependencies)
    return uiModule
  }// end public func makeUIModule
  
  public func makeProductionUIModuleDependencies() throws -> OSCAJobsUIDependencies {
    let module      = try makeProductionModule()
    let uiConfig    = try makeUIModuleConfig()
    let webViewModule = try makeWebViewModule()
    return OSCAJobsUIDependencies( dataModule: module,
                                   moduleConfig: uiConfig,
                                   webViewModule: webViewModule )
  }// end public func makeProductionUIModuleDependencies
  
  public func makeProductionUIModule() throws -> OSCAJobsUI {
    let productionDependencies = try makeProductionUIModuleDependencies()
    // init ui module
    let uiModule = OSCAJobsUI.create(with: productionDependencies)
    return uiModule
  }// end public func makeProductionUIModule
}// end extension OSCAJobsUITests
#endif
