//
//  OSCAJobsMainCellViewModel.swift
//  OSCAJobsUI
//
//  Created by Mammut Nithammer on 19.01.22.
//  Reviewed by Stephan Breidenbach on 21.06.22
//

import Combine
import Foundation
import OSCAJobs

@_implementationOnly
import SwiftDate

public final class OSCAJobsMainCellViewModel {
  var title: String = ""
  var jobType: String = ""
  var dateString: String = ""
  var company: String = ""
  
  var job: OSCAJobPosting
  private let dataModule: OSCAJobs
  private let cellRow: Int
  private var bindings = Set<AnyCancellable>()
  let imageDataCache: NSCache<NSString, NSData>
  
  // MARK: Initializer
  
  public init(imageCache: NSCache<NSString, NSData>,
              job: OSCAJobPosting,
              dataModule: OSCAJobs,
              at row: Int) {
    imageDataCache = imageCache
    self.job = job
    self.dataModule = dataModule
    cellRow = row
    
    setupBindings()
  }
  
  // MARK: - OUTPUT
  
  @Published private(set) var imageData: Data? = nil
  
  var imageDataFromCache: Data? {
    guard let objectId = job.objectId else { return nil }
    let imageData = imageDataCache.object(forKey: NSString(string: objectId))
    return imageData as Data?
  }
  
  // MARK: - Private
  
  private func setupBindings() {
    title = job.title ?? ""
    company = job.hiringOrganization?.name ?? ""
    
    let differenceDays = job.datePosted?.difference(in: .day, from: Date()) ?? 0
    
    switch differenceDays {
    case 0:
      dateString = "Heute"
    case 1:
      dateString = "Gestern"
    case let x where x > 1 && x < 30:
      dateString = "vor \(differenceDays) Tagen"
    case let x where x > 30:
      dateString = "vor 30+ Tagen"
    default:
      dateString = ""
    }
    
    switch job.employmentType {
    case .none:
      jobType = ""
    case .some(.fullTime):
      jobType = "Vollzeit"
    case .some(.partTime):
      jobType = "Teilzeit"
    case .some(.contract):
      jobType = "Minijob"
    }
  }
  
  public func loadImage() {
    if(imageDataFromCache != nil) {
      self.imageData = imageDataFromCache
      return
    }
    
    guard let objectId = job.objectId else { return }
    guard let url = URL(string: job.hiringOrganization?.imageUrl ?? "") else { return }
      DispatchQueue.global().async { [weak self] in
          if let data = try? Data(contentsOf: url) {
            self?.imageData = data
            self?.imageDataCache.setObject(
                NSData(data: data),
                forKey: NSString(string: objectId)
            )
          }
      }
  }
}


// MARK: - INPUT. View event methods
extension OSCAJobsMainCellViewModel {
  func didSetViewModel() {
      loadImage()
  }
}
