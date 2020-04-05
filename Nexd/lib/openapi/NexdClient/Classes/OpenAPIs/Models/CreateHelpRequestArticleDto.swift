//
// CreateHelpRequestArticleDto.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation


public struct CreateHelpRequestArticleDto: Codable { 


    /** Article ID received from the article list */
    public var articleId: Int64
    /** Number of items */
    public var articleCount: Int64

    public init(articleId: Int64, articleCount: Int64) {
        self.articleId = articleId
        self.articleCount = articleCount
    }

}
