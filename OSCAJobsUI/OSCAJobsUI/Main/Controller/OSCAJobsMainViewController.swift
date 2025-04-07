//
//  OSCAJobsMainViewController.swift
//  OSCAJobsUI
//
//  Created by Mammut Nithammer on 19.01.22.
//

import OSCAEssentials
import OSCAJobs
import UIKit
import Combine

public final class OSCAJobsMainViewController: UIViewController, Alertable {
  
  @IBOutlet private var collectionView: UICollectionView!
  
  public lazy var activityIndicationView = ActivityIndicatorView(style: .large)
  
  private typealias DataSource = UICollectionViewDiffableDataSource<OSCAJobsMainViewModel.Section, OSCAJobPosting>
  private typealias Snapshot = NSDiffableDataSourceSnapshot<OSCAJobsMainViewModel.Section, OSCAJobPosting>
  private var viewModel: OSCAJobsMainViewModel!
  private var bindings = Set<AnyCancellable>()
  
  private var dataSource: DataSource!
  
  override public func viewDidLoad() {
    super.viewDidLoad()
    self.setupViews()
    self.setupBindings()
    self.setupSelectedItemBinding()
    self.viewModel.viewDidLoad()
  }
  
  private func setupViews() {
    self.collectionView.delegate = self
    
    let searchController = UISearchController(searchResultsController: nil)
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = self.viewModel.searchPlaceholder
    searchController.isActive = true
    
    self.navigationItem.searchController = searchController
    self.navigationItem.title = self.viewModel.screenTitle
    
    if let textfield = searchController.searchBar.value(forKey: "searchField") as? UITextField {
      textfield.textColor = OSCAJobsUI.configuration.colorConfig.blackColor
      textfield.tintColor = OSCAJobsUI.configuration.colorConfig.navigationTintColor
      textfield.backgroundColor = OSCAJobsUI.configuration.colorConfig.grayLighter
      textfield.leftView?.tintColor = OSCAJobsUI.configuration.colorConfig.whiteColor.darker(componentDelta: 0.3)
      textfield.returnKeyType = .done
      textfield.keyboardType = .default
      textfield.enablesReturnKeyAutomatically = false
      
      if let clearButton = textfield.value(forKey: "_clearButton") as? UIButton {
        let templateImage = clearButton.imageView?.image?.withRenderingMode(.alwaysTemplate)
        clearButton.setImage(templateImage, for: .normal)
        clearButton.tintColor = OSCAJobsUI.configuration.colorConfig.grayDarker
      }
      
      if let label = textfield.value(forKey: "placeholderLabel") as? UILabel {
        label.attributedText = NSAttributedString(
          string: self.viewModel.searchPlaceholder,
          attributes: [.foregroundColor: OSCAJobsUI.configuration.colorConfig.whiteColor.darker(componentDelta: 0.3)])
      }
    }
    
    self.view.backgroundColor = OSCAJobsUI.configuration.colorConfig.backgroundColor
    self.view.addSubview(self.activityIndicationView)
    
    self.activityIndicationView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      self.activityIndicationView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
      self.activityIndicationView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
      self.activityIndicationView.heightAnchor.constraint(equalToConstant: 100.0),
      self.activityIndicationView.widthAnchor.constraint(equalToConstant: 100.0),
    ])
    
    self.collectionView.backgroundColor = .clear
    self.setupCollectionView()
  }
  
  private func setupBindings() {
    self.viewModel.$jobs
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] jobs in
        guard let `self` = self else { return }
        self.configureDataSource()
        self.updateSections(jobs)
      })
      .store(in: &self.bindings)
    
    self.viewModel.$searchedJobs
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] jobs in
        guard let `self` = self else { return }
        self.configureDataSource()
        self.updateSections(jobs)
      })
      .store(in: &self.bindings)
    
    let stateValueHandler: (OSCAJobsMainViewModelState) -> Void = { [weak self] state in
      guard let `self` = self else { return }
      
      switch state {
      case .loading:
        self.startLoading()
        
      case .finishedLoading:
        self.finishLoading()
        
      case let .error(error):
        self.finishLoading()
        self.showAlert(
          title: self.viewModel.alertTitleError,
          error: error,
          actionTitle: self.viewModel.alertActionConfirm)
      }
    }
    
    self.viewModel.$state
      .receive(on: RunLoop.main)
      .sink(receiveValue: stateValueHandler)
      .store(in: &self.bindings)
  }
  
  public override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.setup(
      largeTitles: true,
      tintColor: OSCAJobsUI.configuration.colorConfig.navigationTintColor,
      titleTextColor: OSCAJobsUI.configuration.colorConfig.navigationTitleTextColor,
      barColor: OSCAJobsUI.configuration.colorConfig.navigationBarColor)
  }
  
  private func setupCollectionView() {
    let nib = UINib(nibName: OSCAJobsMainCollectionViewCell.identifier,
                    bundle: OSCAJobsUI.bundle)
    self.collectionView.register(
      nib,
      forCellWithReuseIdentifier: OSCAJobsMainCollectionViewCell.identifier)
    self.collectionView.collectionViewLayout = self.createLayout()
  }
  
  private func createLayout() -> UICollectionViewLayout {
    let size = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(80))
    let item = NSCollectionLayoutItem(layoutSize: size)
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
    
    let section = NSCollectionLayoutSection(group: group)
    section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    section.interGroupSpacing = 8
    
    return UICollectionViewCompositionalLayout(section: section)
  }
  
  private func startLoading() {
    self.collectionView.isUserInteractionEnabled = false
    
    self.activityIndicationView.isHidden = false
    self.activityIndicationView.startAnimating()
  }
  
  private func finishLoading() {
    self.collectionView.isUserInteractionEnabled = true
    
    self.activityIndicationView.stopAnimating()
  }
  
  private func updateSections(_ jobs: [OSCAJobPosting]) {
    var snapshot = Snapshot()
    snapshot.appendSections([.jobs])
    snapshot.appendItems(jobs)
    self.dataSource.apply(snapshot, animatingDifferences: true)
  }
}

extension OSCAJobsMainViewController {
  private func configureDataSource() -> Void {
    self.dataSource = DataSource(
      collectionView: self.collectionView,
      cellProvider: { (collectionView, indexPath, job) -> UICollectionViewCell in
        guard let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: OSCAJobsMainCollectionViewCell.identifier,
          for: indexPath) as? OSCAJobsMainCollectionViewCell
        else { return UICollectionViewCell() }
        
        cell.viewModel = OSCAJobsMainCellViewModel(
          imageCache: self.viewModel.imageDataCache,
          job: job,
          dataModule: self.viewModel.dataModule,
          at: indexPath.row)
        
        return cell
      })
  }
}

extension OSCAJobsMainViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    self.viewModel.didSelectItem(at: indexPath.row)
  }
}

extension OSCAJobsMainViewController: UISearchResultsUpdating {
  public func updateSearchResults(for searchController: UISearchController) {
    guard let text = searchController.searchBar.text else { return }
    self.viewModel.updateSearchResults(for: text)
  }
}

// MARK: - instantiate view conroller
extension OSCAJobsMainViewController: StoryboardInstantiable {
  /// function call: var vc = OSCAPressReleaseMainViewController.create(viewModel)
  public static func create(with viewModel: OSCAJobsMainViewModel) -> OSCAJobsMainViewController {
#if DEBUG
    print("\(String(describing: self)): \(#function)")
#endif
    let vc: Self = Self.instantiateViewController(OSCAJobsUI.bundle)
    vc.viewModel = viewModel
    return vc
  }
}

// MARK: - Deeplinking
extension OSCAJobsMainViewController {
  
  private func setupSelectedItemBinding() -> Void {
    self.viewModel.$selectedItem
      .receive(on: RunLoop.main)
      .dropFirst()
      .sink(receiveValue: { [weak self] selectedItem in
        guard let `self` = self
        else { return }
        if let selectedItem = selectedItem {
          self.selectItem(with: selectedItem)
        }
      })
      .store(in: &self.bindings)
  }// end private func setupSelectedItemBinding
  
  private func selectItem(with index: Int) -> Void {
    let indexPath: IndexPath = IndexPath(row: index, section: 0)
    self.collectionView.selectItem(at: indexPath,
                              animated: true,
                              scrollPosition: .top)
    self.collectionView(self.collectionView, didSelectItemAt: indexPath)
  }// end private func selectItem with index
  
  func didReceiveDeeplinkDetail(with objectId: String) -> Void {
    self.viewModel.didReceiveDeeplinkDetail(with: objectId)
  }// end func didReceiveDeeplinkDetail
}// end extension OSCAJobsMainViewController
