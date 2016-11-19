import XCTest
@testable import GEOJSONKit

class GEOJSONKitTests: XCTestCase {
    
    func path() -> String {
        let parent = (#file).components(separatedBy: "/").dropLast().joined(separator: "/")
        return parent
    }
    
    enum GeometryPosition: Int {
        case point
        case multiPoint
        case lineString
        case polygon
        case multiPolygon
        case multiLineString
        case geometryCollection
    }
    
    // Load Supporting File
    func loadJSON(filename: String) -> [String: Any] {
        let jsonURL = URL(fileURLWithPath: self.path() + "/Supporting/\(filename)")
        let data = try! Data(contentsOf: jsonURL)
        let dictionary = (try! JSONSerialization.jsonObject(with: data, options: [])) as! [String: AnyObject]
        
        return dictionary

    }
    
    func getGeometryCollection() -> [GEOJSONGeometry<GEOJSONLocationCoordinate>] {
        let geometryCollectionDictionary = loadJSON(filename: "GeometryCollection.json")
        let geometryCollection = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: geometryCollectionDictionary)
        
        switch geometryCollection! {
        case .geometryCollection(let geometries):
           return geometries
        default:
            return []
        }

    }
    
    func testGEOJSONGeometryCollection() {
        let geometryCollectionDictionary = loadJSON(filename: "GeometryCollection.json")
        let geometryArray = geometryCollectionDictionary["geometries"] as? [[String: Any]] ?? []
        let geometryCollection = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: geometryCollectionDictionary)
        
        XCTAssertNotNil(geometryCollection)
        switch geometryCollection! {
        case .geometryCollection(let geometries):
            XCTAssertEqual(geometries.count, geometryArray.count)
        default:
            XCTAssert(false, "Expected a Geometry Collection")
        }
    }
    
    func loadGeometryDictionary(with position: GeometryPosition) -> [String: Any] {
        let geometryCollectionDictionary = loadJSON(filename: "GeometryCollection.json")
        let geometriesDictionary = geometryCollectionDictionary["geometries"] as! [[String: Any]]
        return geometriesDictionary[position.rawValue]
    }
    
    func testGEOJSONGeometryPoint() {
        
        let pointDictionary = loadGeometryDictionary(with: .point)
        
        let pointGeometry = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: pointDictionary)
        switch pointGeometry! {
        case .point(let point):
            XCTAssertEqualWithAccuracy(point.longitude, 100.0, accuracy: 0.01)
            XCTAssertEqualWithAccuracy(point.latitude, 0, accuracy: 0.01)
        default:
            XCTAssert(false, "Expected a Geometry Point")
        }
    }
    
    func testGEOJSONMultiPoint() {
        let multiPointDictionary = loadGeometryDictionary(with: .multiPoint)
        let multiPointGeometry = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: multiPointDictionary)
        switch multiPointGeometry! {
        case .multiPoint(let points):
            XCTAssertEqual(points.count, 2)
        default:
            XCTAssert(false, "Expected a Geometry MultiPoint")
        }
    }
    
    func testGEOJSONLineString() {
        let lineStringDictionary = loadGeometryDictionary(with: .lineString)
        let lineStringGeometry = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: lineStringDictionary)
        switch lineStringGeometry! {
        case .lineString(let points):
            XCTAssertEqual(points.count, 2)
        default:
            XCTAssert(false, "Expected a Geometry LineString")
        }
    }
    
    func testGEOJSONPolygon() {
        let polygonDictionary = loadGeometryDictionary(with: .polygon)
        let polygonGeometry = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: polygonDictionary)
        
        switch polygonGeometry! {
        case .polygon(let lines):
            XCTAssertEqual(lines.count, 1)
            XCTAssertEqual(lines[0].count, 5)
        default:
            XCTAssert(false, "Expected a Geometry Polygon")
        }
    }
    
    func testGEOJSONMultiPolygon() {
        let polygonDictionary = loadGeometryDictionary(with: .multiPolygon)
        let polygonGeometry = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: polygonDictionary)
        
        switch polygonGeometry! {
        case .multiPolygon(let polygons):
            XCTAssertEqual(polygons.count, 2)
            XCTAssertEqual(polygons[0].count, 1)
            XCTAssertEqual(polygons[1].count, 2)
            XCTAssertEqual(polygons[0][0].count, 5)
            XCTAssertEqual(polygons[1][0].count, 5)
            XCTAssertEqual(polygons[1][1].count, 5)
        default:
            XCTAssert(false, "Expected a Geometry Multi Polygon")
        }
    }
    
    func testGEOJSONMultiLineString() {
        let multiLineStringDictionary = loadGeometryDictionary(with: .multiLineString)
        let multiLineGeometry = GEOJSONGeometry<GEOJSONLocationCoordinate>(json: multiLineStringDictionary)
         switch multiLineGeometry! {
         case .multiLineString(let lines):
            XCTAssertEqual(lines.count, 2)
            XCTAssertEqual(lines[0].count, 2)
            XCTAssertEqual(lines[1].count, 2)
            
         default:
            XCTAssert(false, "Expected a Geometry Multi Line String")
        }
    }
    
    func testGEOJSONFeatureCollection() {
        let featureCollectionDictionary = loadJSON(filename: "FeatureCollection.json")
        let featureCollection = GEOJSONFeatureCollection<GEOJSONLocationCoordinate>(json: featureCollectionDictionary)
        
        XCTAssertNotNil(featureCollection)
        let featureDictionaries = featureCollectionDictionary["features"] as? [[String: Any]]
        XCTAssertEqual(featureCollection?.features.count, featureDictionaries?.count)
    }
    
    func loadGEOJSONFeatureCollection() -> GEOJSONFeatureCollection<GEOJSONLocationCoordinate>? {
        let featureCollectionDictionary = loadJSON(filename: "FeatureCollection.json")
        return  GEOJSONFeatureCollection<GEOJSONLocationCoordinate>(json: featureCollectionDictionary)
    }
    
    func testGEOJSONFeature() {
        
        let featureCollection =  loadGEOJSONFeatureCollection()
        let feature = featureCollection!.features[1]
        
        // Verify Properties
        let property0 = feature.properties["prop0"] as? String
        let property1 = feature.properties["prop1"] as? NSNumber

        XCTAssertNotNil(property0)
        XCTAssertNotNil(property1)
        XCTAssertEqual(property0, "value0")
        XCTAssertEqual(property1?.floatValue, 0.0)
        
        // Verify Geometry Type
        switch feature.geometry {
        case .lineString:
            break
        default:
            XCTAssert(false, "Expected Line String")
        }
    }
    
    func testGEOJSONInvalidFeature() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let feature = GEOJSONFeature<GEOJSONLocationCoordinate>(json: featuresDictionary[0])
        
        XCTAssertNil(feature)
    }
    
    func testGEOJSONInvalidMultiPointFeature() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let feature = GEOJSONFeature<GEOJSONLocationCoordinate>(json: featuresDictionary[1])
        
        XCTAssertNil(feature)
    }
    
    func testGEOJSONInvalidPolygonFeature() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let feature = GEOJSONFeature<GEOJSONLocationCoordinate>(json: featuresDictionary[2])
        
        XCTAssertNil(feature)
    }
    
    
    func testGEOJSONInvalidFeatureWithoutValues() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let feature = GEOJSONFeature<GEOJSONLocationCoordinate>(json: featuresDictionary[3])
        
        XCTAssertNil(feature)
    }
    
    func testGEOJSONInvalidFeatureWithWrongType() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let feature = GEOJSONFeature<GEOJSONLocationCoordinate>(json: featuresDictionary[4])
        
        XCTAssertNil(feature)
    }
    
    
    func testGEOJSONInvalidCollection() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let featureCollection = GEOJSONFeatureCollection<GEOJSONLocationCoordinate>(json: featuresDictionary[0])
        XCTAssertNil(featureCollection)
    }
    
    
    func testGEOJSONInvalidGeometryCollectionFeature() {
        let invalidFeatureDictionary = loadJSON(filename: "InvalidFeature.json")
        let featuresDictionary = invalidFeatureDictionary["features"] as! [[String: Any]]
        let feature = GEOJSONFeature<GEOJSONLocationCoordinate>(json: featuresDictionary[5])
        
        XCTAssertNil(feature)
    }
    
    func testGEOJSONFeatureWithBoundingBox() {
        
   
        let featureCollection =  loadGEOJSONFeatureCollection()
        
        let feature = featureCollection!.features[0]
        XCTAssertNotNil(feature.boundingBox)
        XCTAssertEqual(feature.boundingBox?.count, 2)
        
        // Verify Values
        XCTAssertEqual(feature.boundingBox![0].longitude, -10.0)
        XCTAssertEqual(feature.boundingBox![0].latitude, -10.0)
        XCTAssertEqual(feature.boundingBox![1].longitude, 11.0)
        XCTAssertEqual(feature.boundingBox![1].latitude, 10.0)

    }
    
    func testGEOJSONFeatureCollectionWithBoundingBox() {
        let featureCollectionDictionary = loadJSON(filename: "FeatureCollection2.json")
        let featureCollection = GEOJSONFeatureCollection<GEOJSONLocationCoordinate>(json: featureCollectionDictionary)
        XCTAssertNotNil(featureCollection?.boundingBox)
    }
    
    func testGEOJSONFeatureCollectionForiegnMembersAccess() {
   
        let featureCollection = loadGEOJSONFeatureCollection()
        
        
        let layerName = featureCollection!["layerName"]
        XCTAssertNotNil(layerName)
        XCTAssertEqual(layerName as? String, "My data")
    }
    

    static var allTests : [(String, (GEOJSONKitTests) -> () throws -> Void)] {
        return [
            ("testExample", testGEOJSONGeometryCollection),
        ]
    }
}
