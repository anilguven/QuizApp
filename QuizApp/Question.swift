//
//  Question.swift
//  QuizApp
//
//  Created by Anil Guven on 16/09/2023.
//

import UIKit

struct Question: Decodable, Hashable {
    
    enum CodingKeys: String, CodingKey {
        case imageName = "image_name"
        case hint
        case answer
    }
    
    let imageName: String
    let hint: String
    let answer: String
}
