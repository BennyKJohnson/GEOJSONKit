![GEOJSON Library](https://s21.postimg.org/bx6gl4w4n/GEOJSON_Icon.png)

GEOJSON Kit makes it super simple to work with GEOJSON data in Swift. GEOJSON Kit automatically maps GEOJSON data into strongly typed objects based on the [RFC 7946 specifications](https://tools.ietf.org/html/rfc7946).

## Features
- [x] Based on the [RFC 7946 specifications](https://tools.ietf.org/html/rfc7946)
- [x] Customise coordinate data type
- [x] 100% tested
- [x] Linux Compatable

## Installation
### Swift Package Manager
Add the following to dependencies in your `Package.swift`.
```swift
.Package(url: "https://github.com/BennyKJohnson/GEOJSONKit.git", majorVersion: 0, minor: 1)
```
Or create the 'Package.swift' file for your project and add the following:
```swift
import PackageDescription

let package = Package(
	dependencies: [
		.Package(url: "https://github.com/BennyKJohnson/GEOJSONKit.git", majorVersion: 0, minor: 1),
	]
)
```
### Manually
Just add GEOJSON.swift to your project.

## Getting Started
```swift
guard let jsonObject = (try? JSONSerialization.jsonObject(with: jsonData, options: [])) as? [String: Any] else {
    return nil
}

let featureCollection = GEOJSONFeatureCollection<GEOJSONLocationCoordinate>(json: jsonObject)!

// Access Foreign members
let layerName = featureCollection["layerName"] as? String

for feature in featureCollection.features {
    
    // Feature Properties
    let name = feature.properties["name"] as? String
    
    // Bounding Box
    let boundingBox = feature.boundingBox
    
    // Geometry
    let geometry = feature.geometry
    
    switch geometry {
    case .point(let coordinate):
        print("Found coordinate: \(coordinate)")
    case .polygon(let polygon):
        print("Found Polygon: \(polygon)")
    default:
        print("Found other geometry")
    }
}

```
