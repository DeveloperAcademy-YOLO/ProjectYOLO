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

class CardPencilKitViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver {
    
    let canvasView = PKCanvasView(frame: .zero)
    let toolPicker = PKToolPicker()
    
    var arrStickers: [String] = ["Halloween_Pumpkin", "Halloween_Candy", "Halloween_Bat", "Halloween_Ghost", "Halloween_StickCandy", "Halloween_Pumpkin", "Halloween_Bat", "Halloween_Ghost", "Halloween_Candy", "Halloween_StickCandy", "Halloween_StickCandy", "Halloween_Bat", "Halloween_Pumpkin", "Halloween_StickCandy", "Halloween_Candy"]
    
    var backgroundImg = UIImage(named: "Rectangle")
    
    private var isCanvasToggle: Bool = true
    private var isStickerToggle: Bool = true
    private var imageSticker: UIImage!
    
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
        someImageView.backgroundColor = .gray
        someImageView.layer.masksToBounds = true
        someImageView.layer.cornerRadius = 50
        someImageView.contentMode = .scaleAspectFill
        someImageView.image = backgroundImg
        someImageViewConstraints()
        
        someImageView.addSubview(canvasView)
        
        pencilKitAppear()
        toolPickerAppear()
        stickerCollectionViewDisappear()
        
        view.addSubview(buttonLabel)
        buttonLabel.layer.masksToBounds = true
        buttonLabel.layer.cornerRadius = 30
        buttonLabelConstraints()
        
        view.addSubview(pencilToggleButton)
        pencilToggleButtonConstraints()
        
        view.addSubview(stickerToggleButton)
        stickerToggleButtonConstraints()
    }
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.backgroundColor = .white
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.isUserInteractionEnabled = true
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
        setCollectionView.backgroundColor = .white
        return setCollectionView
    }()
    
    lazy var buttonLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .white
        return label
    }()
    
    lazy var pencilToggleButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(toggleToolKit(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stickerToggleButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "sparkles")
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(stickerToolKit(_:)), for: .touchUpInside)
        return button
    }()
    
    @objc func toggleToolKit(_ gesture: UITapGestureRecognizer) {
        self.isCanvasToggle.toggle()
        if isCanvasToggle == true {
            toolPickerAppear()
        } else {
            toolPickerDisappear()
        }
    }
    
    @objc func stickerToolKit(_ gesture: UITapGestureRecognizer) {
        self.isStickerToggle.toggle()
        if isStickerToggle == true {
            stickerCollectionViewDisappear()
            print("true")
        } else {
            stickerCollectionViewAppear()
            print("false")
        }
    }
    
    func toolPickerAppear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
    }
    
    func toolPickerDisappear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
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
    
    func pencilKitAppear() {
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        someImageView.image = backgroundImg?.withTintColor(UIColor(named: "darkGray") ?? UIColor(red: 100, green: 200, blue: 200), renderingMode: .alwaysOriginal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
            make.width.equalTo(250)
            make.height.equalTo(450)
            make.leading.equalTo(-160)
            make.centerY.equalTo(self.view)
        })
    }
    
    func pencilToggleButtonConstraints() {
        pencilToggleButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(buttonLabel.snp.top).offset(20)
        })
    }
    
    func stickerToggleButtonConstraints() {
        stickerToggleButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(20)
            make.top.equalTo(pencilToggleButton.snp.bottom).offset(50)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
}

extension CardPencilKitViewController: UICollectionViewDelegate, UICollectionViewDataSource {
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
