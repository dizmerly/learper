import Foundation

// A tiny assertion adapter for Command Line Tools, which do not ship XCTest.swiftmodule.
// The test cases use real XCTest when built by Swift Package Manager in Xcode.
open class XCTestCase {
    public required init() { }
}

private enum TestState {
    static var failures = 0

    static func fail(_ message: String, file: StaticString, line: UInt) {
        failures += 1
        print("\(file):\(line): error: \(message)")
    }
}

public func XCTAssertTrue(
    _ expression: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if !expression() { TestState.fail(message().isEmpty ? "Expected true" : message(), file: file, line: line) }
}

public func XCTAssertFalse(
    _ expression: @autoclosure () -> Bool,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if expression() { TestState.fail(message().isEmpty ? "Expected false" : message(), file: file, line: line) }
}

public func XCTAssertEqual<Value: Equatable>(
    _ actual: @autoclosure () -> Value,
    _ expected: @autoclosure () -> Value,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let left = actual()
    let right = expected()
    if left != right {
        TestState.fail(message().isEmpty ? "Expected \(right), got \(left)" : message(), file: file, line: line)
    }
}

public func XCTAssertNil<Value>(
    _ expression: @autoclosure () -> Value?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if expression() != nil { TestState.fail("Expected nil", file: file, line: line) }
}

public func XCTAssertNotNil<Value>(
    _ expression: @autoclosure () -> Value?,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    if expression() == nil { TestState.fail("Expected a value", file: file, line: line) }
}

public func XCTAssertThrowsError<Value>(
    _ expression: @autoclosure () throws -> Value,
    file: StaticString = #filePath,
    line: UInt = #line,
    _ handler: (Error) -> Void = { _ in }
) {
    do {
        _ = try expression()
        TestState.fail("Expected an error", file: file, line: line)
    } catch {
        handler(error)
    }
}

public struct UnwrapError: Error { }

public func XCTUnwrap<Value>(
    _ expression: @autoclosure () -> Value?,
    file: StaticString = #filePath,
    line: UInt = #line
) throws -> Value {
    guard let value = expression() else {
        TestState.fail("Expected a value", file: file, line: line)
        throw UnwrapError()
    }
    return value
}

public struct TestCaseEntry {
    let name: String
    let tests: [(String, () throws -> Void)]
}

@MainActor
public func testCase<Case: XCTestCase>(
    _ tests: [(String, (Case) -> () throws -> Void)]
) -> TestCaseEntry {
    TestCaseEntry(
        name: String(describing: Case.self),
        tests: tests.map { name, method in
            (name, { try method(Case())() })
        }
    )
}

@MainActor
public func XCTMain(_ cases: [TestCaseEntry]) {
    var runCount = 0
    for testClass in cases {
        for (name, run) in testClass.tests {
            runCount += 1
            let before = TestState.failures
            do {
                try run()
            } catch {
                TestState.fail("Unexpected error: \(error)", file: #filePath, line: #line)
            }
            let result = before == TestState.failures ? "PASS" : "FAIL"
            print("\(result) \(testClass.name).\(name)")
        }
    }
    print("Executed \(runCount) tests; \(TestState.failures) failures")
    if TestState.failures > 0 { exit(1) }
}
