//
//  NetworkLayer.swift
//  CombineNetworkLayer
//
//  Created by 김태훈 on 2023/05/24.
//
import Combine
import Foundation

enum NetworkError: Error {
case invalidURL
case invalidResponse
case decodingError
}

enum HTTPMethod: String {
  case GET
  case POST
  case PUT
  case DELETE
}

enum NetworkResult<T> {
  case sucess(T)
  case failure
}

final class NetworkLayer {
  let baseURL: URL
  let session : URLSession
  
  init(session: URLSession = .shared, baseURL: URL) {
    self.session = session
    self.baseURL = baseURL
  }
  
  func request<T: Decodable>(_ method: HTTPMethod, path: String, queryItems: [URLQueryItem] = [], headers: [String: String] = [:]) -> AnyPublisher<T, Error> {
    let url = URLComponents(
      string: baseURL.appendingPathComponent(path).absoluteString
    )!
    
    var request = URLRequest(url: url.url!)
    request.allHTTPHeaderFields = headers
    request.httpMethod = method.rawValue
    
    return session.dataTaskPublisher(for: request)
      .tryMap { data, response -> Data in
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
          throw URLError(.badServerResponse)
        }
        return data
      }
      .decode(type: T.self, decoder: JSONDecoder())
      .mapError {error in
        error
      }
      .eraseToAnyPublisher()
  }
}

