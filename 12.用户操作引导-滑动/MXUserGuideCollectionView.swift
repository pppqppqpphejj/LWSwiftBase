//
//  MXUserGuideCollectionView.swift
//  leocar
//
//  Created by CodeRiding on 2018/8/21.
//  Copyright © 2018年 com.lcsoft. All rights reserved.
//

import UIKit

class MXUserGuideCollectionView: NSObject
{
    var collectionView:UICollectionView!
    let userGuideDatasourceDelegate = MXUserGuideCellSourceDelegate()
    
    func createView() -> UICollectionView
    {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize.init(width: SCREEN_WIDTH, height: SCREEN_HEIGHT)
        layout.scrollDirection = .horizontal
        
        collectionView = UICollectionView.init(frame: CGRect.init(x: 0, y: 0, width: SCREEN_WIDTH, height: SCREEN_HEIGHT), collectionViewLayout: layout)
        collectionView.register(UINib.init(nibName: "CarListGuide1", bundle: nil), forCellWithReuseIdentifier: "CarListGuide1")
        collectionView?.delegate = userGuideDatasourceDelegate;
        collectionView?.dataSource = userGuideDatasourceDelegate;
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = UIColor.clear
        
        return collectionView
    }

}
