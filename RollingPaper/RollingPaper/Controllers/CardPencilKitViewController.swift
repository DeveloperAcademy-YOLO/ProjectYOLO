//
//  PencilKitViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/05.
//

import UIKit
import PencilKit
import StickerView
import SnapKit
import Combine

class CardPencilKitViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
    let canvasView = PKCanvasView(frame: .zero)
    let toolPicker = PKToolPicker()
    
    private var arrStickers: [String] = ["Halloween_Pumpkin", "Halloween_Candy", "Halloween_Bat", "Halloween_Ghost", "Halloween_StickCandy", "Halloween_Pumpkin", "Halloween_Bat", "Halloween_Ghost", "Halloween_Candy", "Halloween_StickCandy", "Halloween_StickCandy", "Halloween_Bat", "Halloween_Pumpkin", "Halloween_StickCandy", "Halloween_Candy"]
    
    private var backgroundImg = UIImage(named: "Rectangle")
    
    private let viewModel: CardViewModel
    let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    private var isCanvasToolToggle: Bool = true
    private var isStickerToggle: Bool = true
    private var imageSticker: UIImage!
    
    init(viewModel: CardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var _selectedStickerView: StickerView?
    var selectedStickerView: StickerView? {
        get {
            return _selectedStickerView
        }
        set {
            // if other sticker choosed then resign the handler
            if _selectedStickerView != newValue {
                if let selectedStickerView = _selectedStickerView {
                    selectedStickerView.showEditingHandlers = false
                }
                _selectedStickerView = newValue
            }
            // assign handler to new sticker added
            if let selectedStickerView = _selectedStickerView {
                selectedStickerView.showEditingHandlers = true
                selectedStickerView.superview?.bringSubviewToFront(selectedStickerView)
            }
        }
    } 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        view.addSubview(someImageView)
        someImageViewConstraints()
        
        someImageView.addSubview(canvasView)
        
        canvasViewAppear()
        toolPickerAppear()
        stickerCollectionViewDisappear()
        
        view.addSubview(buttonLabel)
        buttonLabelConstraints()
        
        view.addSubview(pencilOnButton)
        pencilOnButtonConstraints()
        
        view.addSubview(stickerOffButton)
        stickerOffButtonConstraints()
    
        input.send(.viewDidLoad)
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        canvasViewAppear()
        toolPickerAppear()
    }
    // TODO: viewDidDisappear이런데에 input 코드 넣으면 네이게이션 돌아 올떄 터짐
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(let background):
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = background
                        print("get background ImgSuccess")
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
                    })
                case .getRecentCardResultImgSuccess(_):
                    DispatchQueue.main.async(execute: {

                    })
                case .getRecentCardResultImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
                        print("getRecentCardResultImgFail")
                    })
                }
            })
            .store(in: &cancellables)
    }
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
        theImageView.backgroundColor = .systemBackground
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 50
        theImageView.contentMode = .scaleAspectFill
        theImageView.image = backgroundImg
        return theImageView
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.scrollDirection = .horizontal
        let setCollectionView: UICollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        setCollectionView.dataSource = self
        setCollectionView.delegate = self
        setCollectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: "StickerCollectionViewCell")
        setCollectionView.backgroundColor = .systemBackground
        return setCollectionView
    }()
    
    lazy var buttonLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemBackground
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 30
        label.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return label
    }()
    
    lazy var pencilOnButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = .black
        button.addTarget(self, action: #selector(toggleToolKit(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var pencilOffButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(toggleToolKit(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stickerOnButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "stickerToogleOn"), for: .normal)
        button.setImage(UIImage(named: "stickerToogleOn"), for: .highlighted)
        button.addTarget(self, action: #selector(stickerToolKit(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stickerOffButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "stickerToogleOff"), for: .normal)
        button.setImage(UIImage(named: "stickerToogleOff"), for: .highlighted)
        button.addTarget(self, action: #selector(stickerToolKit(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func toggleToolKit(_ gesture: UITapGestureRecognizer) {
        selectedStickerView?.showEditingHandlers = false
        self.isCanvasToolToggle.toggle()
        if isCanvasToolToggle == true {
            pencilOnButtonAppear()
            toolPickerAppear()
        } else {
            pencilOffButtonAppear()
            toolPickerDisappear()
        }
    }
    
    @objc func stickerToolKit(_ gesture: UITapGestureRecognizer) {
        self.isStickerToggle.toggle()
        if isStickerToggle == true {
            selectedStickerView?.showEditingHandlers = false
            stickerOffButtonAppear()
            stickerCollectionViewDisappear()
        } else {
            stickerOnButtonAppear()
            stickerCollectionViewAppear()
        }
    }
    
    func resultImageSend() {
        self.selectedStickerView?.showEditingHandlers = false
        let image = self.mergeImages(imageView: self.someImageView)
        self.input.send(.setCardResultImg(result: image ?? UIImage(systemName: "heart.fill")!))
    }
    
    func toolPickerAppear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
    }
    
    func toolPickerDisappear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
    }
    
    func pencilOnButtonAppear() {
        view.addSubview(pencilOnButton)
        pencilOnButtonConstraints()
    }
    
    func pencilOffButtonAppear() {
        view.addSubview(pencilOffButton)
        pencilOffButtonConstraints()
    }
    
    func stickerOnButtonAppear() {
        view.addSubview(stickerOnButton)
        stickerOnButtonConstraints()
    }
    
    func stickerOffButtonAppear() {
        view.addSubview(stickerOffButton)
        stickerOffButtonConstraints()
    }
    
    func stickerCollectionViewAppear() {
        view.addSubview(collectionView)
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = 50
        collectionView.isHidden = false
        collectionViewConstraints()
    }
    
    func stickerCollectionViewDisappear() {
        view.addSubview(collectionView)
        collectionView.layer.masksToBounds = true
        collectionView.layer.cornerRadius = 100
        collectionView.isHidden = true
        collectionViewConstraints()
    }
    
    func canvasViewAppear() {
        canvasView.delegate = self
        canvasView.layer.masksToBounds = true
        canvasView.layer.cornerRadius = 50
        canvasView.contentMode = .scaleAspectFill
        canvasView.isOpaque = false
        canvasView.alwaysBounceVertical = true
        canvasView.drawingPolicy = .anyInput
        canvasView.translatesAutoresizingMaskIntoConstraints = true
        canvasView.becomeFirstResponder()
        canvasViewConstraints()
    }
    
    func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }

    func collectionViewConstraints() {
        collectionView.snp.makeConstraints({ make in
            make.width.equalTo(730)
            make.height.equalTo(100)
            make.centerX.equalTo(self.view)
            make.top.equalTo(someImageView.snp.bottom).offset(10)
        })
    }
    
    func canvasViewConstraints() {
        canvasView.snp.makeConstraints({ make in
            make.width.equalTo(813)
            make.height.equalTo(515)
            make.centerX.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    func buttonLabelConstraints() {
        buttonLabel.snp.makeConstraints({ make in
            make.width.equalTo(100)
            make.height.equalTo(450)
            make.leading.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    func pencilOnButtonConstraints() {
        pencilOnButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(20)
        })
    }
    
    func pencilOffButtonConstraints() {
        pencilOffButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(20)
        })
    }
    
    func stickerOnButtonConstraints() {
        stickerOnButton.snp.makeConstraints({ make in
            make.width.equalTo(80.7)
            make.height.equalTo(63.76)
            make.leading.equalTo(buttonLabel.snp.leading).offset(10)
            make.top.equalTo(buttonLabel.snp.top).offset(90)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
    
    func stickerOffButtonConstraints() {
        stickerOffButton.snp.makeConstraints({ make in
            make.width.equalTo(80.7)
            make.height.equalTo(63.76)
            make.leading.equalTo(buttonLabel.snp.leading).offset(10)
            make.top.equalTo(buttonLabel.snp.top).offset(90)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
}

extension CardPencilKitViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func mergeImages(imageView: UIImageView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0.0)
        imageView.superview!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let renderer = UIGraphicsImageRenderer(size: imageView.frame.size)
        let image = renderer.image(actions: { _ in
            imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
        })
        UIGraphicsEndImageContext()
        return image
    }
    
    func resizedImage(image: UIImage?, width: CGFloat, height: CGFloat) -> UIImage? {
         guard let image = image else { return nil }
         let newSize = CGSize(width: width, height: height)
         UIGraphicsBeginImageContextWithOptions(newSize, false, UIScreen.main.scale)
         image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
         let newImage = UIGraphicsGetImageFromCurrentImageContext()
         UIGraphicsEndImageContext()
         return newImage
     }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let aCell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionViewCell", for: indexPath) as? StickerCollectionViewCell else {return UICollectionViewCell()}
        aCell.myImage.image = UIImage(named: self.arrStickers[indexPath.item])
        return aCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Click Collection cell \(indexPath.item)")
        if let cell = collectionView.cellForItem(at: indexPath) as? StickerCollectionViewCell {
            if let imageSticker = cell.myImage.image {
                let testImage = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))
                testImage.image = imageSticker
                testImage.contentMode = .scaleAspectFit
                let stickerView3 = StickerView.init(contentView: testImage)
                stickerView3.center = CGPoint.init(x: 150, y: 150)
                stickerView3.delegate = self
                stickerView3.setImage(UIImage.init(named: "Close")!, forHandler: StickerViewHandler.close)
                stickerView3.setImage(UIImage.init(named: "Rotate")!, forHandler: StickerViewHandler.rotate)
                stickerView3.setImage(UIImage.init(named: "Flip")!, forHandler: StickerViewHandler.flip)
                stickerView3.showEditingHandlers = false
                stickerView3.tag = 999
                self.someImageView.addSubview(stickerView3)
                self.selectedStickerView = stickerView3
            } else {
                print("Sticker not loaded")
            }
        }
    }
}

extension CardPencilKitViewController: StickerViewDelegate {
    func stickerViewDidTap(_ stickerView: StickerView) {
        self.selectedStickerView = stickerView
    }
    
    func stickerViewDidBeginMoving(_ stickerView: StickerView) {
        self.selectedStickerView = stickerView
    }
    
    func stickerViewDidChangeMoving(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidEndMoving(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidBeginRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidChangeRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidEndRotating(_ stickerView: StickerView) {
        
    }
    
    func stickerViewDidClose(_ stickerView: StickerView) {
        
    }
}

private class StickerCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "StickerCollectionViewCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 셀에 이미지 뷰 객체를 넣어주기 위해서 생성
    let myImage: UIImageView = {
        let img = UIImageView()
        // 자동으로 위치 정렬 금지
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()
    
    func setupView() {
        // 셀에 위에서 만든 이미지 뷰 객체를 넣어준다.
        addSubview(myImage)
        myImageConstraints()
    }
    
    func myImageConstraints() {
        myImage.snp.makeConstraints({ make in
            make.top.equalTo(self.myImage)
            make.left.equalTo(self.myImage)
            make.right.equalTo(self.myImage)
            make.bottom.equalTo(self.myImage)
        })
    }
}

extension UIButton {
    func setUIImage(systemName: String) {
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        imageView?.contentMode = .scaleAspectFit
        imageEdgeInsets = .zero
        setImage(UIImage(systemName: systemName), for: .normal)
    }
}
