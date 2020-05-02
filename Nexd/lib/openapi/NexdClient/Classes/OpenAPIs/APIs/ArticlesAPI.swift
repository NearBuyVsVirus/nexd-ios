//
// ArticlesAPI.swift
//
// Generated by openapi-generator
// https://openapi-generator.tech
//

import Foundation
import RxSwift



open class ArticlesAPI {
    /**
     List articles
     
     - parameter limit: (query) Maximum number of articles  (optional)
     - parameter startsWith: (query) Starts with the given string. Empty string does not filter. (optional)
     - parameter language: (query)  (optional)
     - parameter onlyVerified: (query) true to only gets the list of curated articles (default: true) (optional)
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - returns: Observable<[Article]>
     */
    open class func articlesControllerFindAll(limit: Double? = nil, startsWith: String? = nil, language: AvailableLanguages? = nil, onlyVerified: Bool? = nil, apiResponseQueue: DispatchQueue = NexdClientAPI.apiResponseQueue) -> Observable<[Article]> {
        return Observable.create { observer -> Disposable in
            articlesControllerFindAllWithRequestBuilder(limit: limit, startsWith: startsWith, language: language, onlyVerified: onlyVerified).execute(apiResponseQueue) { result -> Void in
                switch result {
                case let .success(response):
                    observer.onNext(response.body!)
                case let .failure(error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    /**
     List articles
     - GET /article/articles
     - parameter limit: (query) Maximum number of articles  (optional)
     - parameter startsWith: (query) Starts with the given string. Empty string does not filter. (optional)
     - parameter language: (query)  (optional)
     - parameter onlyVerified: (query) true to only gets the list of curated articles (default: true) (optional)
     - returns: RequestBuilder<[Article]> 
     */
    open class func articlesControllerFindAllWithRequestBuilder(limit: Double? = nil, startsWith: String? = nil, language: AvailableLanguages? = nil, onlyVerified: Bool? = nil) -> RequestBuilder<[Article]> {
        let path = "/article/articles"
        let URLString = NexdClientAPI.basePath + path
        let parameters: [String:Any]? = nil
        
        var url = URLComponents(string: URLString)
        url?.queryItems = APIHelper.mapValuesToQueryItems([
            "limit": limit?.encodeToJSON(), 
            "startsWith": startsWith?.encodeToJSON(), 
            "language": language?.encodeToJSON(), 
            "onlyVerified": onlyVerified?.encodeToJSON()
        ])

        let requestBuilder: RequestBuilder<[Article]>.Type = NexdClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

    /**
     Create an article
     
     - parameter createArticleDto: (body)  
     - parameter apiResponseQueue: The queue on which api response is dispatched.
     - returns: Observable<Article>
     */
    open class func articlesControllerInsertOne(createArticleDto: CreateArticleDto, apiResponseQueue: DispatchQueue = NexdClientAPI.apiResponseQueue) -> Observable<Article> {
        return Observable.create { observer -> Disposable in
            articlesControllerInsertOneWithRequestBuilder(createArticleDto: createArticleDto).execute(apiResponseQueue) { result -> Void in
                switch result {
                case let .success(response):
                    observer.onNext(response.body!)
                case let .failure(error):
                    observer.onError(error)
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }

    /**
     Create an article
     - POST /article/articles
     - parameter createArticleDto: (body)  
     - returns: RequestBuilder<Article> 
     */
    open class func articlesControllerInsertOneWithRequestBuilder(createArticleDto: CreateArticleDto) -> RequestBuilder<Article> {
        let path = "/article/articles"
        let URLString = NexdClientAPI.basePath + path
        let parameters = JSONEncodingHelper.encodingParameters(forEncodableObject: createArticleDto)

        let url = URLComponents(string: URLString)

        let requestBuilder: RequestBuilder<Article>.Type = NexdClientAPI.requestBuilderFactory.getBuilder()

        return requestBuilder.init(method: "POST", URLString: (url?.string ?? URLString), parameters: parameters, isBody: true)
    }

}
