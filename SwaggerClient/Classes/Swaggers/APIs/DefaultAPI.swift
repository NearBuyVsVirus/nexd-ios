//
// DefaultAPI.swift
//
// Generated by swagger-codegen
// https://github.com/swagger-api/swagger-codegen
//

import Foundation
import Alamofire


open class DefaultAPI {
    /**

     - parameter completion: completion handler to receive the data and the error objects
     */
    open class func appControllerRoot(completion: @escaping ((_ data: Void?,_ error: Error?) -> Void)) {
        appControllerRootWithRequestBuilder().execute { (response, error) -> Void in
            if error == nil {
                completion((), error)
            } else {
                completion(nil, error)
            }
        }
    }


    /**
     - GET /
     - 

     - :
       - type: http
       - name: bearer

     - returns: RequestBuilder<Void> 
     */
    open class func appControllerRootWithRequestBuilder() -> RequestBuilder<Void> {
        let path = "/"
        let URLString = SwaggerClientAPI.basePath + path
        let parameters: [String:Any]? = nil

        let url = URLComponents(string: URLString)

        let requestBuilder: RequestBuilder<Void>.Type = SwaggerClientAPI.requestBuilderFactory.getNonDecodableBuilder()

        return requestBuilder.init(method: "GET", URLString: (url?.string ?? URLString), parameters: parameters, isBody: false)
    }

}
