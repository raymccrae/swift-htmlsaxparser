HTML SAX Parser for Swift 3
======
**HTMLSAXParser** is a swift module that wraps the libxml2 HTMLParser for the purposes
of providing a simple lightweight SAX parser for HTML content. libxml2 is part of the
Mac, iOS and Apple TV SDK, if you are developing for those platforms then you will not
require any additional dependencies. SAX parsers provide an event based parsing process,
where a closure you provide will be called with a series of events as the parser moves
through the document.

**HTMLSAXParser** take inspiration from NSXMLParser however it uses enums with associated
types for the parsing events, rather than a delegate class. A simple of example of usage
is: -

```swift
let parser = HTMLSAXParser()
do {
	try parser.parse(string: "<html><body>Some HTML Content</body></html>") { event in
		switch event {
			case let .startElement(name, attributes, location):
				print("Found character : \(name)")
			case let .character(text, _):
				print("Found character : \(text)")
			default:
				break
		}
	}
}
catch {
	// Handle error
}
```

This approach lends itself to short inlined processing of HTML without the need for
a parser delegate class.

```swift
/**
 Example function to extract all the image sources from HTML data. Specifically
 fetching the "src" attribute from all "img" tags.
*/
func imageSources(from htmlData: Data) throws -> [String] {
	var sources: [String] = []
	let parser = HTMLSAXParser()
	try parser.parse(data: htmlData) { event in
		switch event {
			case let .startElement(name, attributes, _) when name == "img":
				if let source = attributes["src"] {
					sources.append(source)
				}
			default:
				break
		}
	}
}
```

## Contributors

### Contributors on GitHub
* [Contributors](https://github.com/raymccrae/swift-htmlsaxparser/graphs/contributors)

## License 
* see [LICENSE](https://github.com/raymccrae/swift-htmlsaxparser/blob/master/LICENSE) file

## Version 
* Version 0.1