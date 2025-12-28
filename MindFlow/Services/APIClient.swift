import Foundation
import Combine

class APIClient: ObservableObject {
    static let shared = APIClient()
    
    // 启用模拟数据模式（不需要服务器）
    // 设置为 true 时，应用将使用内存存储，不需要后端服务器
    // 设置为 false 时，需要后端服务器运行在 baseURL
    private let useMockData: Bool = true
    
    // 配置 API 基础 URL
    // 开发环境：iOS 模拟器可以使用 localhost
    // 真机测试需要替换为你的电脑 IP 地址（例如: http://192.168.1.100:5000）
    private let baseURL: String = {
        #if DEBUG
        return "http://localhost:5000"
        #else
        return "https://your-server.com"
        #endif
    }()
    
    private let session: URLSession
    
    // 模拟数据存储（仅在 useMockData = true 时使用）
    private var mockCategories: [Category] = []
    private var mockItems: [Item] = []
    private var mockProperties: [CategoryProperty] = []
    private var nextCategoryId = 1
    private var nextItemId = 1
    private var nextPropertyId = 1
    
    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
        
        // 初始化一些示例数据
        if useMockData {
            initializeMockData()
        }
    }
    
    private func initializeMockData() {
        // 添加一些示例分类
        mockCategories = [
            Category(id: 1, name: "电子产品", description: "手机、电脑等", parentId: nil, icon: "📱"),
            Category(id: 2, name: "服装", description: "衣服、鞋子等", parentId: nil, icon: "👕"),
            Category(id: 3, name: "食品", description: "各种食物", parentId: nil, icon: "🍔")
        ]
        nextCategoryId = 4
        
        // 添加一些示例商品
        mockItems = [
            Item(id: 1, name: "iPhone 15", brand: "Apple", categoryId: 1, price: "7999", colorTier: "gold", notes: "最新款", properties: ["_rank": "1"], purchaseDate: nil),
            Item(id: 2, name: "MacBook Pro", brand: "Apple", categoryId: 1, price: "12999", colorTier: "purple", notes: nil, properties: ["_rank": "2"], purchaseDate: nil)
        ]
        nextItemId = 3
    }
    
    // MARK: - Generic Request Method
    private func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError(message: "Invalid URL", field: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError(message: "Failed to encode request body", field: nil)
            }
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(message: "Invalid response", field: nil)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorData = try? JSONDecoder().decode(APIError.self, from: data) {
                    throw errorData
                }
                throw APIError(message: "Server error: \(httpResponse.statusCode)", field: nil)
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            // 处理网络连接错误
            let errorMessage: String
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "无法连接到网络，请检查网络设置"
            case .timedOut:
                errorMessage = "连接超时，请稍后重试"
            case .cannotFindHost, .cannotConnectToHost:
                errorMessage = "无法连接到服务器，请确认服务器地址是否正确：\(baseURL)"
            default:
                errorMessage = "网络错误：\(urlError.localizedDescription)"
            }
            throw APIError(message: errorMessage, field: nil)
        } catch {
            throw APIError(message: error.localizedDescription, field: nil)
        }
    }
    
    // MARK: - Request Method for Void (no return value)
    private func request(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError(message: "Invalid URL", field: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                request.httpBody = try JSONEncoder().encode(body)
            } catch {
                throw APIError(message: "Failed to encode request body", field: nil)
            }
        }
        
        do {
            let (_, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError(message: "Invalid response", field: nil)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError(message: "Server error: \(httpResponse.statusCode)", field: nil)
            }
        } catch let error as APIError {
            throw error
        } catch let urlError as URLError {
            // 处理网络连接错误
            let errorMessage: String
            switch urlError.code {
            case .notConnectedToInternet:
                errorMessage = "无法连接到网络，请检查网络设置"
            case .timedOut:
                errorMessage = "连接超时，请稍后重试"
            case .cannotFindHost, .cannotConnectToHost:
                errorMessage = "无法连接到服务器，请确认服务器地址是否正确：\(baseURL)"
            default:
                errorMessage = "网络错误：\(urlError.localizedDescription)"
            }
            throw APIError(message: errorMessage, field: nil)
        } catch {
            throw APIError(message: error.localizedDescription, field: nil)
        }
    }
    
    // MARK: - Categories
    func getCategories(parentId: Int? = nil) async throws -> [Category] {
        if useMockData {
            // 模拟延迟
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            if let parentId = parentId {
                return mockCategories.filter { $0.parentId == parentId }
            }
            return mockCategories.filter { $0.parentId == nil }
        }
        
        var endpoint = "/api/categories"
        if let parentId = parentId {
            endpoint += "?parentId=\(parentId)"
        }
        return try await request(endpoint: endpoint)
    }
    
    func getCategory(id: Int) async throws -> Category {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            guard let category = mockCategories.first(where: { $0.id == id }) else {
                throw APIError(message: "Category not found", field: nil)
            }
            return category
        }
        
        return try await request(endpoint: "/api/categories/\(id)")
    }
    
    func createCategory(_ body: CreateCategoryRequest) async throws -> Category {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            let newCategory = Category(
                id: nextCategoryId,
                name: body.name,
                description: body.description,
                parentId: body.parentId,
                icon: body.icon
            )
            nextCategoryId += 1
            mockCategories.append(newCategory)
            return newCategory
        }
        
        return try await request(endpoint: "/api/categories", method: "POST", body: body)
    }
    
    func updateCategory(id: Int, _ body: CreateCategoryRequest) async throws -> Category {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            guard let index = mockCategories.firstIndex(where: { $0.id == id }) else {
                throw APIError(message: "Category not found", field: nil)
            }
            let updatedCategory = Category(
                id: id,
                name: body.name,
                description: body.description,
                parentId: body.parentId,
                icon: body.icon
            )
            mockCategories[index] = updatedCategory
            return updatedCategory
        }
        
        return try await request(endpoint: "/api/categories/\(id)", method: "PUT", body: body)
    }
    
    func deleteCategory(id: Int) async throws {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            mockCategories.removeAll { $0.id == id }
            // 同时删除该分类下的商品
            mockItems.removeAll { $0.categoryId == id }
            return
        }
        
        try await request(endpoint: "/api/categories/\(id)", method: "DELETE")
    }
    
    // MARK: - Properties
    func getProperties(categoryId: Int) async throws -> [CategoryProperty] {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            return mockProperties.filter { $0.categoryId == categoryId }
        }
        
        return try await request(endpoint: "/api/categories/\(categoryId)/properties")
    }
    
    func createProperty(_ body: CreatePropertyRequest) async throws -> CategoryProperty {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            let newProperty = CategoryProperty(
                id: nextPropertyId,
                categoryId: body.categoryId,
                name: body.name,
                type: body.type,
                options: body.options
            )
            nextPropertyId += 1
            mockProperties.append(newProperty)
            return newProperty
        }
        
        return try await request(endpoint: "/api/properties", method: "POST", body: body)
    }
    
    func updateProperty(id: Int, name: String) async throws -> CategoryProperty {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            guard let index = mockProperties.firstIndex(where: { $0.id == id }) else {
                throw APIError(message: "Property not found", field: nil)
            }
            let property = mockProperties[index]
            let updatedProperty = CategoryProperty(
                id: id,
                categoryId: property.categoryId,
                name: name,
                type: property.type,
                options: property.options
            )
            mockProperties[index] = updatedProperty
            return updatedProperty
        }
        
        struct UpdatePropertyBody: Codable {
            let name: String
        }
        let body = UpdatePropertyBody(name: name)
        return try await request(endpoint: "/api/properties/\(id)", method: "PUT", body: body)
    }
    
    func deleteProperty(id: Int) async throws {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            mockProperties.removeAll { $0.id == id }
            return
        }
        
        try await request(endpoint: "/api/properties/\(id)", method: "DELETE")
    }
    
    // MARK: - Items
    func getItems(categoryId: Int) async throws -> [Item] {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            return mockItems.filter { $0.categoryId == categoryId }
        }
        
        return try await request(endpoint: "/api/categories/\(categoryId)/items")
    }
    
    func createItem(_ body: CreateItemRequest) async throws -> Item {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            let newItem = Item(
                id: nextItemId,
                name: body.name,
                brand: body.brand,
                categoryId: body.categoryId,
                price: body.price,
                colorTier: body.colorTier ?? "gray",
                notes: body.notes,
                properties: body.properties,
                purchaseDate: nil
            )
            nextItemId += 1
            mockItems.append(newItem)
            return newItem
        }
        
        return try await request(endpoint: "/api/items", method: "POST", body: body)
    }
    
    func updateItem(id: Int, _ body: UpdateItemRequest) async throws -> Item {
        if useMockData {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
            guard let index = mockItems.firstIndex(where: { $0.id == id }) else {
                throw APIError(message: "Item not found", field: nil)
            }
            let item = mockItems[index]
            let updatedItem = Item(
                id: id,
                name: body.name ?? item.name,
                brand: body.brand ?? item.brand,
                categoryId: item.categoryId,
                price: body.price ?? item.price,
                colorTier: body.colorTier ?? item.colorTier,
                notes: body.notes ?? item.notes,
                properties: body.properties ?? item.properties,
                purchaseDate: item.purchaseDate
            )
            mockItems[index] = updatedItem
            return updatedItem
        }
        
        return try await request(endpoint: "/api/items/\(id)", method: "PUT", body: body)
    }
    
    func deleteItem(id: Int) async throws {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            mockItems.removeAll { $0.id == id }
            return
        }
        
        try await request(endpoint: "/api/items/\(id)", method: "DELETE")
    }
    
    func updateItemColorTier(id: Int, colorTier: String) async throws -> Item {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            guard let index = mockItems.firstIndex(where: { $0.id == id }) else {
                throw APIError(message: "Item not found", field: nil)
            }
            let item = mockItems[index]
            let updatedItem = Item(
                id: id,
                name: item.name,
                brand: item.brand,
                categoryId: item.categoryId,
                price: item.price,
                colorTier: colorTier,
                notes: item.notes,
                properties: item.properties,
                purchaseDate: item.purchaseDate
            )
            mockItems[index] = updatedItem
            return updatedItem
        }
        
        struct UpdateColorTierBody: Codable {
            let colorTier: String
        }
        let body = UpdateColorTierBody(colorTier: colorTier)
        return try await request(endpoint: "/api/items/\(id)/color-tier", method: "PATCH", body: body)
    }
    
    func updateItemRank(id: Int, rank: Int) async throws -> Item {
        if useMockData {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            guard let index = mockItems.firstIndex(where: { $0.id == id }) else {
                throw APIError(message: "Item not found", field: nil)
            }
            let item = mockItems[index]
            var properties = item.properties ?? [:]
            properties["_rank"] = String(rank)
            let updatedItem = Item(
                id: id,
                name: item.name,
                brand: item.brand,
                categoryId: item.categoryId,
                price: item.price,
                colorTier: item.colorTier,
                notes: item.notes,
                properties: properties,
                purchaseDate: item.purchaseDate
            )
            mockItems[index] = updatedItem
            return updatedItem
        }
        
        struct UpdateRankBody: Codable {
            let rank: Int
        }
        let body = UpdateRankBody(rank: rank)
        return try await request(endpoint: "/api/items/\(id)/rank", method: "PATCH", body: body)
    }
}

