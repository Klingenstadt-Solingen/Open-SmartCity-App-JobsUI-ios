//
//  OSCAJobsMainCollectionViewCell.swift
//  OSCAJobsUI
//
//  Created by Mammut Nithammer on 19.01.22.
//

import OSCAEssentials
import UIKit
import Combine

public final class OSCAJobsMainCollectionViewCell: UICollectionViewCell {
  
  @IBOutlet public var contentStackView: UIStackView!
  @IBOutlet public var imageView: UIImageView!
  @IBOutlet public var titleLabel: UILabel!
  @IBOutlet public var companyLabel: UILabel!
  @IBOutlet public var dateLabel: UILabel!
  @IBOutlet public var typeLabel: UILabel!

  public static let identifier = String(describing: OSCAJobsMainCollectionViewCell.self)
  private var bindings = Set<AnyCancellable>()
  
  public var viewModel: OSCAJobsMainCellViewModel! {
    didSet {
      self.setupView()
      self.setupBindings()
      self.viewModel.didSetViewModel()
    }
  }
  
  private func setupView() {
    self.contentView.backgroundColor = OSCAJobsUI.configuration.colorConfig.secondaryBackgroundColor
    self.contentView.layer.cornerRadius = OSCAJobsUI.configuration.cornerRadius
    self.contentView.layer.masksToBounds = true
    
    self.addShadow(with: OSCAJobsUI.configuration.shadowSettings)
    
    self.titleLabel.text = viewModel.title
    self.typeLabel.text = viewModel.jobType
    self.dateLabel.text = viewModel.dateString
    self.companyLabel.text = viewModel.company
    
    self.titleLabel.font = OSCAJobsUI.configuration.fontConfig.bodyHeavy
    self.companyLabel.font = OSCAJobsUI.configuration.fontConfig.captionLight
    self.dateLabel.font = OSCAJobsUI.configuration.fontConfig.smallLight
    self.typeLabel.font = OSCAJobsUI.configuration.fontConfig.smallLight
    
    self.titleLabel.textColor = OSCAJobsUI.configuration.colorConfig.textColor
    self.companyLabel.textColor = OSCAJobsUI.configuration.colorConfig.textColor
    self.dateLabel.textColor = OSCAJobsUI.configuration.colorConfig.whiteColor.darker(componentDelta: 0.5)
    self.typeLabel.textColor = OSCAJobsUI.configuration.colorConfig.whiteColor.darker(componentDelta: 0.5)
    
    self.imageView.image = self.viewModel.imageDataFromCache == nil
      ? OSCAJobsUI.configuration.placeholderImage
      : UIImage(data: self.viewModel.imageDataFromCache!)
    self.imageView.contentMode = .scaleAspectFit
    self.imageView.backgroundColor = .clear
    self.imageView.layer.cornerRadius = OSCAJobsUI.configuration.cornerRadius / 2
    self.imageView.layer.masksToBounds = true
  }
  
  private func setupBindings() {
    var sub: AnyCancellable?
    sub = self.viewModel.$imageData
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] imageData in
        guard let `self` = self,
              let imageData = imageData
        else { return }
        if let sub = sub {
          self.bindings.remove(sub)
        }
        self.imageView.image = UIImage(data: imageData)
      })
    guard let sub = sub else { return }
    self.bindings.insert(sub)
  }
  
  private func clearSubscriptions() {
    guard !self.bindings.isEmpty else { return }
    for sub in self.bindings {
      self.bindings.remove(sub)
      sub.cancel()
    }
  }
  
  override public func prepareForReuse() {
    super.prepareForReuse()
    self.clearSubscriptions()
    self.imageView.image = nil
  }
}
