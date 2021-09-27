//
//  ViewController.swift
//  Zoom
//
//  Created by Александр Назаров on 08.09.2021.
//

import UIKit

class ViewController: UIViewController {
    //MARK: - IBOutlet
    @IBOutlet weak var titleRingLabel: UILabel!
    @IBOutlet weak var countRingLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    //fake array in bd
    var imageArray = ["ringImage","ringImage2","ringImage3",
                      "ringImage4","imageRing5","imageRing6",
                      "imageRing7","imageRing8"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCV()
        configureCountLabel()
    }
    
    func configureCountLabel() {
        //конфиг
        countRingLabel.backgroundColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
        countRingLabel.layer.cornerRadius = 4
        countRingLabel.clipsToBounds = true
        // выводим последний элемент из массива
        let lastElement = imageArray.endIndex
        countRingLabel.text = "\(String(describing: lastElement))"
    }
    
    func configureCV() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(RingCell.self, forCellWithReuseIdentifier: "cell")
    }
}
//MARK: - DataSource
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? RingCell {
            let data = self.imageArray [indexPath.item]
            cell.setupCell(image: data)
            cell.layer.cornerRadius = 10
            return cell
        }
        fatalError("cell not create")
    }
}
//MARK: - Delegate collect
extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("\(indexPath)")
        }
    }
//MARK: - Delegate ring protocol
extension ViewController: RingCellDelegate {
    func zooming(started: Bool) {
        self.collectionView.isScrollEnabled = !started
    }
}
