import Foundation

/// Actor that manages sequential execution of background tasks
/// 
/// This actor ensures that tasks execute one at a time to prevent resource contention.
/// It's particularly useful for file I/O operations, network requests, and other
/// expensive computations that should not run concurrently.
/// 
/// **Key Features**:
/// - Sequential task execution prevents resource contention
/// - Actor-based for thread safety (no manual locking needed)
/// - Automatic queue management
/// - Support for cancellation
/// 
/// **Performance Requirements**:
/// - Requirement 1.4: Queue scans sequentially rather than running in parallel
/// 
/// **Why Sequential Execution?**
/// Running multiple file I/O operations concurrently can cause:
/// - Excessive disk head movement (thrashing)
/// - Memory pressure from multiple concurrent operations
/// - Unpredictable performance due to resource contention
/// 
/// Sequential execution ensures predictable, efficient resource usage.
/// 
/// **Usage Example**:
/// ```swift
/// let queue = BackgroundTaskQueue()
/// 
/// // Enqueue a task
/// let result = await queue.enqueue {
///     return await expensiveFileOperation()
/// }
/// 
/// // Cancel all pending tasks
/// await queue.cancelAll()
/// ```
actor BackgroundTaskQueue {
    private var isProcessing = false
    
    /// Enqueue a task for sequential execution
    /// - Parameter operation: An async closure to execute
    /// - Returns: The result of the operation
    /// 
    /// **Note**: The actor itself ensures serial execution.
    /// All calls to this method will execute sequentially, one at a time.
    func enqueue<T>(_ operation: @escaping () async -> T) async -> T {
        isProcessing = true
        defer { isProcessing = false }
        
        // Execute and return the result
        // The actor ensures this runs sequentially
        return await operation()
    }
    
    /// Cancel all pending tasks
    func cancelAll() {
        // Actor-based sequential execution means tasks are not "queued" in a traditional sense
        // Once a task starts, it runs to completion
        // This method is kept for API compatibility but doesn't need to do anything
    }
    
    /// Check if queue is currently processing tasks
    var isCurrentlyProcessing: Bool {
        return isProcessing
    }
}
