//
//  OSCAJobsMainViewModel.swift
//  OSCAJobsUI
//
//  Created by Mammut Nithammer on 19.01.22.
//  Reviewed by Stephan Breidenbach on 21.06.22
//

import Combine
import Foundation
import OSCAJobs

public struct OSCAJobsMainViewModelActions {
  public let showJobsDetail: (OSCAJobPosting) -> Void
  public init(showJobsDetail: @escaping (OSCAJobPosting) -> Void) {
    self.showJobsDetail = showJobsDetail
  }
}

public enum OSCAJobsMainViewModelError: Error, Equatable {
  case jobPostingFetch
}

public enum OSCAJobsMainViewModelState: Equatable {
  case loading
  case finishedLoading
  case error(OSCAJobsMainViewModelError)
}

public final class OSCAJobsMainViewModel {
  let dataModule: OSCAJobs
  private let actions: OSCAJobsMainViewModelActions?
  private var bindings = Set<AnyCancellable>()
  private var selectedItemId: String?
  
  // MARK: Initializer
  
  public init(dataModule: OSCAJobs,
              actions: OSCAJobsMainViewModelActions) {
    self.dataModule = dataModule
    self.actions = actions
  } // end public init
  
  // MARK: - OUTPUT
  
  enum Section { case jobs }
  
  @Published private(set) var state: OSCAJobsMainViewModelState = .loading
  @Published var jobs: [OSCAJobPosting] = []
  @Published var searchedJobs: [OSCAJobPosting] = []
  @Published var isSearching: Bool = false
  @Published var selectedItem: Int? {
    didSet {
      /// selected item id consumed
      self.selectedItemId = nil
    }
  }
  
  /**
   Use this to get access to the __Bundle__ delivered from this module's configuration parameter __externalBundle__.
   - Returns: The __Bundle__ given to this module's configuration parameter __externalBundle__. If __externalBundle__ is __nil__, The module's own __Bundle__ is returned instead.
   */
  var bundle: Bundle = {
    if let bundle = OSCAJobsUI.configuration.externalBundle {
      return bundle
    }
    else { return OSCAJobsUI.bundle }
  }()
  
  let imageDataCache = NSCache<NSString, NSData>()
  
  public func fetchAll() {
    fetchAllJobs()
  }
}

// MARK: - Private

extension OSCAJobsMainViewModel {
  private func fetchAllJobs() {
    state = .loading
    
    dataModule
      .getJobPostings(limit: 1000000)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .error(.jobPostingFetch)
        }
        
      } receiveValue: { result in
        switch result {
        case let .success(fetchedJobs):
          self.jobs = fetchedJobs
            .filter { $0.datePosted != nil }
            .sorted { first, second in
              first.datePosted!.compare(second.datePosted!) == .orderedDescending
            }
          self.selectItem(with: self.selectedItemId)
        case .failure:
          self.state = .error(.jobPostingFetch)
        }
      }
      .store(in: &bindings)
  }
  
  private func fetchJobs(for ids: [String]) {
    let query = ["where": "{\"objectId\":{\"$in\":\(ids)}}"]
    dataModule.getJobPostings(query: query)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .error(.jobPostingFetch)
        }
      } receiveValue: { result in
        switch result {
        case let .success(fetchedJobs):
          self.searchedJobs = fetchedJobs
          
        case .failure:
          self.state = .error(.jobPostingFetch)
        }
      }
      .store(in: &bindings)
  }
  
  private func fetchJobs(for searchText: String) {
    dataModule
      .elasticSearch(for: searchText)
      .sink { completion in
        switch completion {
        case .finished:
          self.state = .finishedLoading
          
        case .failure:
          self.state = .finishedLoading
        }
        
      } receiveValue: { fetchedJobs in
        
        var ids: [String] = []
        for job in fetchedJobs {
          if let id = job._id {
            ids.append(id)
          }
        }
        
        self.fetchJobs(for: ids)
      }
      .store(in: &bindings)
  }
}

// MARK: - INPUT. View event methods

extension OSCAJobsMainViewModel {
  func viewDidLoad() {
    fetchAll()
  }
  
  func didSelectItem(at index: Int) {
    guard (jobs.count + 1) >= index else { return }
    actions?.showJobsDetail(isSearching ? searchedJobs[index] : jobs[index])
  }
  
  func updateSearchResults(for searchText: String) {
    if !searchText.isEmpty {
      isSearching = true
      fetchJobs(for: searchText)
    } else {
      isSearching = false
      searchedJobs = jobs
    }
  }
}

// MARK: - Deeplinking
extension OSCAJobsMainViewModel {
  func didReceiveDeeplinkDetail(with objectId: String) -> Void {
    guard !objectId.isEmpty else { return }
    self.selectedItemId = objectId
    selectItem(with: objectId)
  }// end func didReceiveDeeplinkDetail
  
  private func selectItem(with objectId: String?) -> Void {
    guard let objectId = objectId,
          let index = self.jobs.firstIndex(where: { $0.objectId == objectId})
    else { return }
    self.selectedItem = index
  }// end private func selectItem with object id
}// end extension final class OSCAJobsMainViewModel


// MARK: - OUTOUT, localized strings
extension OSCAJobsMainViewModel {
  var screenTitle: String { return NSLocalizedString(
    "jobs_title",
    bundle: self.bundle,
    comment: "The screen title for press releases") }
  
  var alertTitleError: String { return NSLocalizedString(
    "jobs_alert_title_error",
    bundle: self.bundle,
    comment: "The alert title for an error") }
  
  var alertActionConfirm: String { return NSLocalizedString(
    "jobs_alert_title_confirm",
    bundle: self.bundle,
    comment: "The alert action title to confirm") }
  
  var searchPlaceholder: String {  NSLocalizedString(
    "jobs_search_placeholder",
    bundle: self.bundle,
    comment: "Placeholder for searchbar") }
}// end extension final class OSCAJoabsMainViewModel
