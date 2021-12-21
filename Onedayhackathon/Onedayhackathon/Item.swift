//
//  Item.swift
//  Onedayhackathon
//
//  Created by nju on 2021/12/21.
//

import UIKit

class Item: NSObject {
    var image:UIImage
    var label:String
    
    init(image:UIImage,label:String){
        self.image = image
        self.label = label
    }

}
