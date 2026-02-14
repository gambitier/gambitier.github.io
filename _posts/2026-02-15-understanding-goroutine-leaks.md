---
title: Understanding Goroutine Leaks in Go
date: 2026-02-15
categories: [Go, Concurrency]
tags: [golang, concurrency, debugging]
author: Akash Jadhav
pin: false
---

Concurrency is one of the biggest strengths of Go. With a single `go` keyword, you can spin up lightweight concurrent workers called *goroutines*.

But that simplicity comes with a hidden danger:

> Goroutine leaks.

In this post, we’ll understand:
- What a goroutine leak is  
- Why it happens so easily  
- A real-world example  
- How to prevent it  
- How to detect leaks in tests  

---

## What Is a Goroutine Leak?

A **goroutine leak** happens when a goroutine starts but never exits — even though your program no longer needs it.

Unlike memory leaks in languages like C, Go has garbage collection. But **goroutines are not garbage collected automatically**. If they are blocked or stuck, they remain alive.

Over time, leaked goroutines can:
- Increase memory usage  
- Consume CPU  
- Hold file descriptors or network connections  
- Crash production systems  

---

## Why Goroutine Leaks Are Common in Go

### 1️⃣ Goroutines Are Extremely Cheap

Creating one is easy:

```go
go doSomething()
```

Because they are lightweight, developers often create many of them — sometimes forgetting lifecycle management.

---

### 2️⃣ Channels Can Block Forever

This is the most common cause.

```go
func worker(ch chan int) {
    <-ch  // waits forever if no value arrives
}

func main() {
    ch := make(chan int)
    go worker(ch)
}
```

If nothing sends a value into `ch`, that worker is stuck forever.

Leak.

---

### 3️⃣ Missing Context Cancellation

Modern Go relies heavily on `context.Context`.

If you forget cancellation handling:

```go
go func() {
    for {
        doWork()
    }
}()
```

This loop never exits.

Without cancellation logic, this goroutine lives forever — even after a request ends.

---

### 4️⃣ HTTP Server Example (Real-World Scenario)

Imagine a web handler:

```go
func handler(w http.ResponseWriter, r *http.Request) {
    go process(r.Context())
}
```

If `process()` ignores `r.Context()` cancellation, it continues running even after:
- Client disconnects  
- Request times out  
- Server shuts down  

Over weeks, this leads to thousands of leaked goroutines.

Production memory climbs.
CPU spikes.
Eventually — outage.

---

# How to Prevent Goroutine Leaks

## ✅ 1. Always Use Context Cancellation

```go
func worker(ctx context.Context) {
    for {
        select {
        case <-ctx.Done():
            return
        default:
            doWork()
        }
    }
}
```

If the parent cancels the context, the goroutine exits cleanly.

---

## ✅ 2. Close Channels Properly

When done sending:

```go
close(ch)
```

Receivers can detect closure and exit gracefully.

---

## ✅ 3. Track Goroutines with WaitGroup

```go
var wg sync.WaitGroup

wg.Add(1)
go func() {
    defer wg.Done()
    doWork()
}()

wg.Wait()
```

Never “fire and forget” unless truly intentional.

---

## ✅ 4. Use Timeouts

Timeouts prevent infinite blocking:

```go
ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
defer cancel()
```

Always prefer bounded work.

---

# Detecting Leaks in Tests

There’s an excellent tool:

go.uber.org/goleak

It automatically verifies that no goroutines are left running after a test.

Example:

```go
func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

If a test leaks goroutines, it fails and prints stack traces.

This is extremely valuable in CI pipelines.

---

# Production Debugging Tips

If you suspect leaks:

### 1️⃣ Check Goroutine Count

```go
runtime.NumGoroutine()
```

If it continuously increases under steady traffic → red flag.

---

### 2️⃣ Use pprof

Enable:

```go
import _ "net/http/pprof"
```

Then inspect:
```
/debug/pprof/goroutine
```

You’ll see where goroutines are stuck.

---

# Mental Model

Think of a goroutine like a worker you hired.

If you:
- Don’t tell them when to stop  
- Don’t close the communication channel  
- Don’t wait for them to finish  

They’ll stay in the office forever.

---

# Final Thoughts

Goroutines make Go powerful and elegant. But concurrency always requires lifecycle management.

The golden rules:

- Always use `context`
- Always handle cancellation
- Avoid unbounded loops
- Close channels correctly
- Use leak detection in tests

Do that — and your Go services will stay stable, predictable, and production-ready.