

####调用方法

var guidView:UICollectionView!
    var getColloctionViewTool = MXUserGuideCollectionView()

let c = getColloctionViewTool.createView()
        c.reloadData()
        UIApplication.shared.keyWindow?.addSubview(c)