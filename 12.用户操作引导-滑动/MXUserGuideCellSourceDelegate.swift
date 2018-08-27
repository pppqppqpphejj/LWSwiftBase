//
//  MXUserGuideCellSourceDelegate
//  leocar
//
//  Created by CodeRiding on 2018/8/20.
//  Copyright © 2018年 com.lcsoft. All rights reserved.
//

import UIKit

class MXUserGuideCellSourceDelegate: NSObject {

}

extension MXUserGuideCellSourceDelegate:UICollectionViewDelegate {
    
}

extension MXUserGuideCellSourceDelegate:UICollectionViewDataSource {

    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CarListGuide1", for: indexPath) as! CarListGuide1
//        cell.backgroundColor = UIColor.black
//        cell.alpha = 0.6
        return cell
    }
}

extension MXUserGuideCellSourceDelegate:UICollectionViewDelegateFlowLayout {
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: SCREEN_WIDTH, height: SCREEN_HEIGHT);
    }
    
    /// 行与行之间
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0;
    }
    
    /// cell与cell之间
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0;
    }
}
