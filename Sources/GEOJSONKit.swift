import Foundation
public protocol GEOJSONCoordinateType {
    
    var latitude: Double { get }
    
    var longitude: Double { get }
    
    init(latitude: Double, longitude: Double)
}

public protocol GEOJSONType {
    init?(json: [String: Any])
}

enum GEOJSONGeometryType: String {
    
    case point = "Point"
    
    case multiPoint = "MultiPoint"
    
    case lineString = "LineString"
    
    case multiLineString = "MultiLineString"
    
    case polygon = "Polygon"
    
    case multiPolygon = "MultiPolygon"
    
    case geometryCollection = "GeometryCollection"
    
}

public struct GEOJSONLocationCoordinate: GEOJSONCoordinateType {
    
    public let latitude: Double
    
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public enum GEOJSONGeometry<CoordinateType: GEOJSONCoordinateType>: GEOJSONType  {
    
    case point(GEOJSONCoordinateType)
    
    case polygon([[GEOJSONCoordinateType]])
    
    case lineString([GEOJSONCoordinateType])
    
    case multiPoint([GEOJSONCoordinateType])
    
    case multiLineString([[GEOJSONCoordinateType]])
    
    case multiPolygon([[[GEOJSONCoordinateType]]])
    
    case geometryCollection([GEOJSONGeometry])
    
    static func parseCoordinate(value: Any) -> GEOJSONCoordinateType? {
        
        guard let coordinateValues = value as? [NSNumber], coordinateValues.count == 2
        else {
                return nil
        }
        
        let longitude = coordinateValues[0].doubleValue
        let latitude = coordinateValues[1].doubleValue
        
        return CoordinateType(latitude: latitude, longitude: longitude)
    }
    
    static func parseCoordinates(value: Any) -> [GEOJSONCoordinateType]? {
        
        guard let coordinateValues = value as? [[NSNumber]] else {
            return nil
        }
        
        return coordinateValues.map({ (coordinateValue) -> GEOJSONCoordinateType in
            return parseCoordinate(value: coordinateValue)!
        })
    }
    
    static func parseNestedCoordinates(value: Any) -> [[GEOJSONCoordinateType]]? {
        guard let coordinateValues = value as? [[[NSNumber]]] else {
            return nil
        }
        
        return coordinateValues.map({ (coordinateCollection) -> [GEOJSONCoordinateType] in
            return parseCoordinates(value: coordinateCollection)!
        })
    }
    
    public init?(json: [String: Any]) {
        guard
            let rawTypeValue = json["type"] as? String,
            let type = GEOJSONGeometryType(rawValue: rawTypeValue)
            else {
                return nil
        }
        
        if let coordinatesValue = json["coordinates"] {
            switch type {
            case .point:
                if let coordinate = GEOJSONGeometry.parseCoordinate(value: coordinatesValue) {
                    self = .point(coordinate)
                    return
                }
            case .lineString:
                if let coordinates = GEOJSONGeometry.parseCoordinates(value: coordinatesValue) {
                    self = .lineString(coordinates)
                    return
                }
            case .multiPoint:
                if let coordinates = GEOJSONGeometry.parseCoordinates(value: coordinatesValue) {
                    self = .multiPoint(coordinates)
                    return
                }
            case .polygon:
                if let coordinates = GEOJSONGeometry.parseNestedCoordinates(value: coordinatesValue) {
                    self = .polygon(coordinates)
                    return
                }
            case .multiLineString:
                if let coordinates = GEOJSONGeometry.parseNestedCoordinates(value: coordinatesValue) {
                    self = .multiLineString(coordinates)
                    return
                }
            case .multiPolygon:
                if let coordinateCollections = coordinatesValue as? [[[[NSNumber]]]] {
                    let geometryValue = coordinateCollections.map({ (coordinateCollection) -> [[GEOJSONCoordinateType]] in
                        return GEOJSONGeometry.parseNestedCoordinates(value: coordinateCollection)!
                    })
                    
                    self = .multiPolygon(geometryValue)
                    return
                }
            case .geometryCollection:
                return nil
            }
            return nil
            
            
        } else if let geometryValues = json["geometries"] as? [[String: Any]] {
                let geometryCollection = geometryValues.flatMap { (dictionary) -> GEOJSONGeometry? in
                    return GEOJSONGeometry(json: dictionary)
                }
                
                self = .geometryCollection(geometryCollection)
            return
        }
        
        return nil
    }
}


public protocol GEOJSONObjectType: GEOJSONType {
    
    var members: [String: Any] { get }
    
    var boundingBox: [GEOJSONCoordinateType]? { get }
    
    associatedtype GEOJSONCoordinate: GEOJSONCoordinateType
}

extension GEOJSONObjectType {
    subscript(key: String) -> Any? {
        get {
            return members[key]
        }
    }
    
    static func parseBoundingBox(values: [NSNumber]) -> [GEOJSONCoordinateType]? {
        var boundingBox = Array<GEOJSONCoordinate>(repeating: GEOJSONCoordinate(latitude: 0,longitude: 0), count: (values.count / 2))
        
        for i in stride(from: 0, to: values.count, by: 2) {
            let longitude = values[i].doubleValue
            let latitude = values[i+1].doubleValue
            boundingBox[i/2] = GEOJSONCoordinate(latitude: latitude, longitude: longitude)
        }
        
        return boundingBox
    }
}


public protocol GEOJSONIdentifierType {}

extension Int: GEOJSONIdentifierType {}

extension String: GEOJSONIdentifierType {}

public struct GEOJSONFeature<FeatureGeometryCoordinateType: GEOJSONCoordinateType>: GEOJSONObjectType {
    
    public typealias GEOJSONCoordinate = FeatureGeometryCoordinateType
    
    public let properties: [String: Any]
    
    public let geometry: GEOJSONGeometry<GEOJSONCoordinate>
    
    public let members: [String: Any]
    
    public let boundingBox: [GEOJSONCoordinateType]?
    
    public let identifier: GEOJSONIdentifierType?
    

    
    public init?(json: [String: Any]) {
        
        identifier = json["id"] as? GEOJSONIdentifierType
        
        guard
            let propertiesDictionary = json["properties"] as? [String: Any],
            let geometryDictionary = json["geometry"] as? [String: Any],
            let geometry = GEOJSONGeometry<GEOJSONCoordinate>(json: geometryDictionary) else {
                return nil
        }
        
        properties = propertiesDictionary
        self.geometry = geometry
        
        if let boundingBoxValue = json["bbox"] as? [NSNumber] {
            
            
            boundingBox = GEOJSONFeatureCollection<GEOJSONCoordinate>.parseBoundingBox(values: boundingBoxValue)
        } else {
            boundingBox = nil
        }
        
        members = json
    }
}

public struct GEOJSONFeatureCollection<FeatureCollectionCoordinateType: GEOJSONCoordinateType>: GEOJSONObjectType {
    
    public typealias GEOJSONCoordinate = FeatureCollectionCoordinateType
    
    public let features: [GEOJSONFeature<GEOJSONCoordinate>]
    
    public let members: [String: Any]
    
    public let boundingBox: [GEOJSONCoordinateType]?
    
    public init?(json: [String: Any]) {
        
        self.members = json
        
        if let featuresDictionary = json["features"] as? [[String: Any]] {
            features = featuresDictionary.flatMap({ (featuresDictionary) -> GEOJSONFeature<GEOJSONCoordinate>? in
                return GEOJSONFeature<GEOJSONCoordinate>(json: featuresDictionary)
            })
        } else {
            return nil
        }
        
        if let boundingBoxValue = json["bbox"] as? [NSNumber] {
            boundingBox = GEOJSONFeatureCollection.parseBoundingBox(values: boundingBoxValue)
        } else {
            boundingBox = nil
        }
    }
}
